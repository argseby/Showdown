import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/admin_api.dart';
import '../../../core/formatting.dart';
import '../../../core/rest_client.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/suit_painter.dart';
import '../../admin/admin_session.dart';
import '../log_text.dart';
import '../table_session.dart';
import '../widgets/table_view.dart';
import 'replay_reducer.dart';

/// Opens the hand replay: a list of the table's hands (loaded with the
/// viewer's session token, or the admin token) and a step-by-step player
/// that renders each step with the normal table view.
Future<void> showReplayDialog(
  BuildContext context, {
  required String tableId,
  required String token,
  required bool admin,
  required Snapshot base,
  int? viewerSeat,
  HandRecord? hand,
}) {
  return showOverlay<void>(
    context,
    const DialogConfiguration(),
    builder: (context) => ReplayDialog(
      tableId: tableId,
      token: token,
      admin: admin,
      base: base,
      viewerSeat: viewerSeat,
      initial: hand,
    ),
  ).future;
}

class ReplayDialog extends ConsumerStatefulWidget {
  const ReplayDialog({
    super.key,
    required this.tableId,
    required this.token,
    required this.admin,
    required this.base,
    this.viewerSeat,
    this.initial,
  });

  final String tableId;
  final String token;
  final bool admin;
  final Snapshot base;
  final int? viewerSeat;
  final HandRecord? initial;

  @override
  ConsumerState<ReplayDialog> createState() => _ReplayDialogState();
}

class _ReplayDialogState extends ConsumerState<ReplayDialog> {
  List<HandRecord>? _hands;
  HandRecord? _hand;
  List<GameEvent> _events = const [];
  int _step = 0;
  bool _playing = false;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _select(widget.initial!);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(adminApiProvider);
      final hands = widget.admin
          ? await api.hands(widget.token, widget.tableId, limit: 100)
          : await api.sessionHands(widget.token, widget.tableId, limit: 100);
      if (mounted) setState(() => _hands = hands);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _select(HandRecord h) {
    _timer?.cancel();
    setState(() {
      _hand = h;
      _events = [for (final raw in h.events) GameEvent.fromJson(raw)];
      _step = 0;
      _playing = false;
    });
  }

  void _seek(int step) {
    setState(() => _step = step.clamp(0, _events.length));
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_step >= _events.length) _step = 0;
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_step >= _events.length) {
        _timer?.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _step++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final size = MediaQuery.sizeOf(context);
    Widget content;
    if (_hand == null) {
      final hands = _hands;
      content = _error != null
          ? Text(l10n.replayLoadFailed(_error!)).muted()
          : hands == null
          ? const Center(child: CircularProgressIndicator())
          : hands.isEmpty
          ? Text(l10n.replayNoHands).muted()
          : SizedBox(
              width: 420,
              height: size.height * 0.5,
              child: ListView(
                children: [
                  for (final h in hands)
                    GhostButton(
                      key: Key('replay-hand-${h.number}'),
                      alignment: Alignment.centerLeft,
                      onPressed: h.voided ? null : () => _select(h),
                      leading: const Icon(LucideIcons.play),
                      child: Text(
                        l10n.adminHandRow(h.number, formatClock(h.startedAt)) +
                            (h.voided ? ' · ${l10n.adminHandVoided}' : ''),
                      ),
                    ),
                ],
              ),
            );
    } else {
      final names = {
        for (final sv in widget.base.seats)
          if (sv.player != null) sv.seat: sv.player!.name,
      };
      final avatars = {
        for (final sv in widget.base.seats)
          if (sv.player != null) sv.seat: sv.player!.avatar,
      };
      final reducer = ReplayReducer(
        events: _events,
        base: widget.base,
        handNumber: _hand!.number,
        names: names,
        avatars: avatars,
        viewerSeat: widget.viewerSeat,
      );
      final frame = reducer.frame(_step);
      final session = TableSessionState(
        snapshot: frame.snapshot,
        identity: YouIdentity(
          role: widget.viewerSeat == null ? 'spectator' : 'player',
          seat: widget.viewerSeat,
        ),
        best: frame.best,
        revealed: frame.revealed,
        winners: frame.winners,
      );
      final line = frame.event == null
          ? l10n.replayStart
          : logLineText(
                  l10n,
                  LogEntry(
                    handNumber: _hand!.number,
                    event: frame.event!,
                    names: names,
                  ),
                  mySeat: widget.viewerSeat,
                  locale: locale,
                ) ??
                '';
      content = SizedBox(
        width: (size.width * 0.9).clamp(320, 900),
        height: (size.height * 0.75).clamp(360, 700),
        child: Column(
          children: [
            Expanded(child: TableView(session: session)),
            const Gap(8),
            Text.rich(
              TextSpan(
                children: cardSpans(
                  line,
                  blackSuit: theme.colorScheme.foreground,
                ),
              ),
              key: const Key('replay-line'),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: SliderValue.single(
                      _events.isEmpty ? 0 : _step / _events.length,
                    ),
                    onChanged: (v) => _seek((v.value * _events.length).round()),
                  ),
                ),
                const Gap(12),
                Text(l10n.replayStep(_step, _events.length)).muted().small(),
              ],
            ),
            const Gap(6),
            Wrap(
              spacing: 6,
              alignment: WrapAlignment.center,
              children: [
                OutlineButton(
                  key: const Key('replay-prev'),
                  size: ButtonSize.small,
                  onPressed: _step == 0 ? null : () => _seek(_step - 1),
                  leading: const Icon(LucideIcons.skipBack),
                  child: Text(l10n.replayPrev),
                ),
                PrimaryButton(
                  key: const Key('replay-play'),
                  size: ButtonSize.small,
                  onPressed: _togglePlay,
                  leading: Icon(
                    _playing ? LucideIcons.pause : LucideIcons.play,
                  ),
                  child: Text(_playing ? l10n.replayPause : l10n.replayPlay),
                ),
                OutlineButton(
                  key: const Key('replay-next'),
                  size: ButtonSize.small,
                  onPressed: _step >= _events.length
                      ? null
                      : () => _seek(_step + 1),
                  leading: const Icon(LucideIcons.skipForward),
                  child: Text(l10n.replayNext),
                ),
                if (widget.initial == null)
                  GhostButton(
                    size: ButtonSize.small,
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _hand = null;
                        _playing = false;
                      });
                    },
                    child: Text(l10n.replayBackToList),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return AlertDialog(
      title: Text(
        _hand == null
            ? l10n.replayTitle
            : l10n.adminHandRow(_hand!.number, formatClock(_hand!.startedAt)),
      ),
      content: content,
      actions: [
        OutlineButton(
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
