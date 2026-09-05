import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/admin_api.dart';
import '../../core/formatting.dart';
import '../../core/rest_client.dart';
import '../../core/session_store.dart';
import '../../protocol/protocol.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/suit_painter.dart';
import '../table/log_text.dart';
import '../table/replay/replay_dialog.dart';
import '../table/table_session.dart';
import 'admin_player_actions.dart';
import 'admin_session.dart';
import 'admin_widgets.dart';
import 'settings_form.dart';
import 'settings_form_model.dart';

/// The host's Admin tab inside the table's side panel: lifecycle controls,
/// the admin key, settings, players, chat moderation and recent hands. All
/// calls use the table's admin token; nothing here is global.
class AdminPanel extends ConsumerStatefulWidget {
  const AdminPanel({super.key, required this.tableId, required this.token});

  final String tableId;
  final String token;

  @override
  ConsumerState<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends ConsumerState<AdminPanel> {
  AdminTableDetail? _detail;
  List<HandRecord>? _hands;
  SettingsFormState? _form;
  Map<String, SettingsError> _errors = const {};
  Map<String, String> _serverErrors = const {};
  bool _saving = false;
  int _tab = 0;
  bool _notFound = false;

  String? get _token => widget.token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// The server rejected the key: drop it so the tab disappears.
  Future<void> _rejected() async {
    await ref.read(adminTokenProvider(widget.tableId).notifier).clear();
    if (mounted) showAdminToast(context, context.l10n.adminKeyRejected);
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) return;
    final api = ref.read(adminApiProvider);
    try {
      final detail = await api.getTable(token, widget.tableId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _form ??= SettingsFormState.fromSettings(detail.settings);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 404) {
        setState(() => _notFound = true);
        return;
      }
      if (e.status == 401) await _rejected();
      return;
    }
    if (!mounted) return;
    final hands = await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => api.hands(token, widget.tableId, limit: 20),
    );
    if (mounted && hands != null) setState(() => _hands = hands);
  }

  Future<void> _save() async {
    final form = _form;
    final token = _token;
    final detail = _detail;
    if (form == null || token == null || detail == null) return;
    final l10n = context.l10n;
    final errors = form.validate(seated: detail.players.length);
    setState(() {
      _errors = errors;
      _serverErrors = const {};
    });
    if (errors.isNotEmpty) return;
    final patch = form.toPatch();
    if (patch.isEmpty) {
      showAdminToast(context, l10n.adminNoChanges);
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(adminApiProvider)
          .patchSettings(token, widget.tableId, patch);
      if (!mounted) return;
      setState(() => _form = SettingsFormState.fromSettings(result.settings));
      showAdminToast(
        context,
        result.appliesNextHand.isEmpty
            ? l10n.adminSaved
            : l10n.adminSavedNextHand(result.appliesNextHand.join(', ')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 401) {
        await _rejected();
        return;
      }
      setState(() {
        _serverErrors = {
          for (final f in e.fields) f.field: f.message,
          if (e.fields.isEmpty && e.field != null) e.field!: e.message,
        };
      });
      if (_serverErrors.isEmpty) {
        showAdminToast(context, l10n.errGeneric(e.message));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _lifecycle(String op, {bool immediate = false}) async {
    final token = _token;
    if (token == null) return;
    final l10n = context.l10n;
    final state = await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => ref
          .read(adminApiProvider)
          .lifecycle(token, widget.tableId, op, immediate: immediate),
    );
    if (state != null && mounted) {
      final label = switch (state) {
        'waiting' => l10n.joinStateWaiting,
        'running' => l10n.joinStateRunning,
        'paused' => l10n.joinStatePaused,
        _ => l10n.joinStateEnded,
      };
      showAdminToast(context, l10n.adminStateChanged(label));
      await _load();
    }
  }

  Future<void> _blindsUp() async {
    final token = _token;
    if (token == null) return;
    final l10n = context.l10n;
    final settings = await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => ref.read(adminApiProvider).blindsUp(token, widget.tableId),
    );
    if (settings != null && mounted) {
      showAdminToast(
        context,
        l10n.adminBlindsRaised('${settings.smallBlind}/${settings.bigBlind}'),
      );
      // The form keeps its edits otherwise; the blinds changed underneath.
      setState(() => _form = SettingsFormState.fromSettings(settings));
      await _load();
    }
  }

  Future<void> _end() async {
    final l10n = context.l10n;
    final choice = await showOverlay<String>(
      context,
      const DialogConfiguration(),
      builder: (context) => AlertDialog(
        title: Text(l10n.adminEndTitle),
        content: Text(l10n.adminEndBody),
        actions: [
          OutlineButton(
            onPressed: () => closeOverlay<String>(context),
            child: Text(l10n.cancel),
          ),
          SecondaryButton(
            onPressed: () => closeOverlay<String>(context, 'after'),
            child: Text(l10n.adminEndAfterHand),
          ),
          DestructiveButton(
            onPressed: () => closeOverlay<String>(context, 'now'),
            child: Text(l10n.adminEndNow),
          ),
        ],
      ),
    ).future;
    if (choice == null || !mounted) return;
    await _lifecycle('end', immediate: choice == 'now');
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    if (_detail?.state == 'running') {
      showAdminToast(context, l10n.adminDeleteRunning);
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminDeleteTitle,
      body: l10n.adminDeleteBody,
      confirmLabel: l10n.adminDelete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final token = _token;
    if (token == null) return;
    final done = await guardAdmin(ref, context, widget.tableId, () async {
      await ref.read(adminApiProvider).deleteTable(token, widget.tableId);
      return true;
    });
    if (done == true && mounted) {
      // The table is gone: forget the seat and the key, back to the start.
      await ref.read(sessionProvider(widget.tableId).notifier).clear();
      await ref.read(adminTokenProvider(widget.tableId).notifier).clear();
      if (mounted) {
        showAdminToast(context, l10n.adminDeleted);
        context.go('/');
      }
    }
  }

  AdminPlayerActions? get _actions {
    final token = _token;
    if (token == null) return null;
    return AdminPlayerActions(
      ref: ref,
      context: context,
      tableId: widget.tableId,
      token: token,
    );
  }

  Future<void> _kick(AdminPlayer p) async {
    if (await _actions?.kick(p.id, p.name) ?? false) {
      if (mounted) await _load();
    }
  }

  Future<void> _chips(AdminPlayer p) async {
    if (await _actions?.chips(p.id, p.name) ?? false) {
      if (mounted) await _load();
    }
  }

  Future<void> _mute(AdminPlayer p) async {
    if (await _actions?.muteChat(p.id, muted: !p.muted) ?? false) {
      if (mounted) await _load();
    }
  }

  Future<void> _muteVoice(AdminPlayer p) async {
    if (await _actions?.muteVoice(p.id) ?? false) {
      if (mounted) await _load();
    }
  }

  Future<void> _removeChat(int id) async {
    final token = _token;
    if (token == null) return;
    await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => ref.read(adminApiProvider).deleteChat(token, widget.tableId, id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final live = ref.watch(tableSessionProvider(widget.tableId));
    ref.listen(
      tableSessionProvider(widget.tableId)
          .select((s) => s.snapshot?.table.state),
      (prev, next) {
        // Reload on real state changes (start, pause, end); the first
        // snapshot after connecting carries no change.
        if (prev != null && prev != next && next != null) _load();
      },
    );
    ref.listen(
      tableSessionProvider(widget.tableId)
          .select((s) => s.snapshot?.table.handNumber),
      (prev, next) {
        if (prev != null && next != null && next != prev && _tab == 3) _load();
      },
    );
    final detail = _detail;
    if (_notFound) {
      return Center(child: Text(l10n.tableNotFound).muted());
    }
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controls = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (detail.state == 'waiting')
          PrimaryButton(
            key: const Key('admin-start'),
            size: ButtonSize.small,
            onPressed: () => _lifecycle('start'),
            leading: const Icon(LucideIcons.play),
            child: Text(l10n.adminStart),
          ),
        if (detail.state == 'running')
          SecondaryButton(
            key: const Key('admin-pause'),
            size: ButtonSize.small,
            onPressed: () => _lifecycle('pause'),
            leading: const Icon(LucideIcons.pause),
            child: Text(l10n.adminPause),
          ),
        if (detail.state == 'paused')
          PrimaryButton(
            key: const Key('admin-resume'),
            size: ButtonSize.small,
            onPressed: () => _lifecycle('resume'),
            leading: const Icon(LucideIcons.play),
            child: Text(l10n.adminResume),
          ),
        if (detail.state != 'ended')
          DestructiveButton(
            key: const Key('admin-end'),
            size: ButtonSize.small,
            onPressed: _end,
            leading: const Icon(LucideIcons.square),
            child: Text(l10n.adminEnd),
          ),
        OutlineButton(
          key: const Key('admin-delete'),
          size: ButtonSize.small,
          onPressed: detail.state == 'running' ? null : _delete,
          leading: const Icon(LucideIcons.trash2),
          child: Text(l10n.adminDelete),
        ),
        if (detail.state != 'ended')
          OutlineButton(
            key: const Key('admin-blinds-up'),
            size: ButtonSize.small,
            onPressed: _blindsUp,
            leading: const Icon(LucideIcons.trendingUp),
            child: Text(l10n.adminBlindsUp),
          ),
      ],
    );

    final keyCard = Card(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminKey).semiBold().small(),
          const Gap(6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              OutlineButton(
                key: const Key('admin-copy-key'),
                size: ButtonSize.small,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.token));
                  showAdminToast(context, l10n.adminKeyCopied);
                },
                leading: const Icon(LucideIcons.key),
                child: Text(l10n.adminKeyCopy),
              ),
            ],
          ),
          const Gap(6),
          Text(l10n.adminKeyHint).muted().small(),
        ],
      ),
    );

    // The panel is narrow: let the tab strip scroll instead of clipping.
    final tabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Tabs(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
        children: [
          TabItem(child: Text(l10n.adminSettings)),
          TabItem(child: Text(l10n.adminPlayers)),
          TabItem(child: Text(l10n.tabChat)),
          TabItem(child: Text(l10n.adminTabHands)),
        ],
      ),
    );

    Widget content;
    switch (_tab) {
      case 0:
        final form = _form!;
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unsaved changes are announced at the top, with Save right there.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: form.hasChanges
                  ? Container(
                      key: const Key('admin-unsaved'),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.adminUnsavedChanges).semiBold().small(),
                          const Gap(8),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  key: const Key('admin-save'),
                                  onPressed: _saving ? null : _save,
                                  leading: const Icon(LucideIcons.save),
                                  child: Text(l10n.adminSave),
                                ),
                              ),
                              const Gap(8),
                              OutlineButton(
                                key: const Key('admin-discard'),
                                onPressed: () => setState(() {
                                  _form = SettingsFormState.fromSettings(
                                    detail.settings,
                                  );
                                  _errors = const {};
                                  _serverErrors = const {};
                                }),
                                child: Text(l10n.adminDiscard),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SettingsForm(
              state: form,
              errors: _errors,
              serverErrors: _serverErrors,
              showPasswordKeepHint: true,
              seated: detail.players.length,
              onChanged: (s) => setState(() => _form = s),
            ),
          ],
        );
      case 1:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in detail.players)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(p.name).semiBold()),
                          const Gap(8),
                          SecondaryBadge(child: Text(p.status)),
                          if (!p.connected) ...[
                            const Gap(4),
                            SecondaryBadge(child: Text(l10n.badgeDisconnected)),
                          ],
                          if (p.muted) ...[
                            const Gap(4),
                            SecondaryBadge(child: Text(l10n.adminMute)),
                          ],
                        ],
                      ),
                      const Gap(4),
                      Text(
                        '${l10n.seatLabel(p.seat)} · ${formatChips(p.stack, locale)} (${(p.stack - p.buyInTotal >= 0 ? '+' : '')}${formatChips(p.stack - p.buyInTotal, locale)}) · ${l10n.lbHandsWon}: ${p.handsWon}/${p.handsPlayed}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const Gap(6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          OutlineButton(
                            size: ButtonSize.small,
                            onPressed: () => _chips(p),
                            child: Text(l10n.adminChips),
                          ),
                          OutlineButton(
                            size: ButtonSize.small,
                            onPressed: () => _mute(p),
                            child: Text(
                              p.muted
                                  ? l10n.adminUnmuteChat
                                  : l10n.adminMuteChat,
                            ),
                          ),
                          if (p.voice == 'on')
                            OutlineButton(
                              size: ButtonSize.small,
                              onPressed: () => _muteVoice(p),
                              leading: const Icon(LucideIcons.micOff, size: 14),
                              child: Text(l10n.adminMuteVoice),
                            ),
                          if (p.voice == 'muted')
                            SecondaryBadge(child: Text(l10n.adminMutedVoice)),
                          DestructiveButton(
                            size: ButtonSize.small,
                            onPressed: () => _kick(p),
                            child: Text(l10n.adminKick),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      case 2:
        final chat = live.chat;
        content = chat.isEmpty
            ? Text(l10n.adminNoChat).muted()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in chat.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            formatClock(m.ts),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'GeistMono',
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${m.authorName}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  ...cardSpans(
                                    m.text,
                                    blackSuit: theme.colorScheme.foreground,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Tooltip(
                            tooltip: TooltipContainer(
                              child: Text(l10n.adminRemoveMessage),
                            ).call,
                            child: GhostButton(
                              density: ButtonDensity.icon,
                              onPressed: () => _removeChat(m.id),
                              child: const Icon(LucideIcons.trash2),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
      default:
        final hands = _hands;
        final names = {for (final p in detail.players) p.seat: p.name};
        content = hands == null
            ? const Center(child: CircularProgressIndicator())
            : hands.isEmpty
            ? Text(l10n.adminNoHands).muted()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final h in hands)
                    _HandTile(
                      hand: h,
                      names: names,
                      locale: locale,
                      onReplay: live.snapshot == null || h.voided
                          ? null
                          : () => showReplayDialog(
                              context,
                              tableId: widget.tableId,
                              token: widget.token,
                              admin: true,
                              base: live.snapshot!,
                              viewerSeat: live.mySeat,
                              hand: h,
                            ),
                    ),
                ],
              );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.adminPlayersCount(detail.players.length, detail.settings.maxPlayers)} · ${l10n.adminSpectatorsWatching(detail.spectators, detail.connections)}',
                ).muted().small(),
              ),
              StateBadge(state: detail.state),
            ],
          ),
          const Gap(8),
          controls,
          const Gap(10),
          keyCard,
          const Gap(10),
          tabs,
          const Gap(10),
          content,
        ],
      ),
    );
  }
}

class _HandTile extends StatefulWidget {
  const _HandTile({
    required this.hand,
    required this.names,
    required this.locale,
    this.onReplay,
  });
  final HandRecord hand;
  final Map<int, String> names;
  final String locale;
  final VoidCallback? onReplay;

  @override
  State<_HandTile> createState() => _HandTileState();
}

class _HandTileState extends State<_HandTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final h = widget.hand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GhostButton(
              onPressed: () => setState(() => _open = !_open),
              alignment: Alignment.centerLeft,
              leading: Icon(
                _open ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.adminHandRow(h.number, formatClock(h.startedAt)),
                    ),
                  ),
                  if (h.voided)
                    SecondaryBadge(child: Text(l10n.adminHandVoided)),
                  if (widget.onReplay != null)
                    GhostButton(
                      size: ButtonSize.small,
                      onPressed: widget.onReplay,
                      leading: const Icon(LucideIcons.rotateCcw),
                      child: Text(l10n.replayOpen),
                    ),
                ],
              ),
            ),
            if (_open) ...[
              const Gap(4),
              for (final raw in h.events)
                if (logLineText(
                      l10n,
                      LogEntry(
                        handNumber: h.number,
                        event: GameEvent.fromJson(raw),
                        names: widget.names,
                      ),
                      locale: widget.locale,
                    )
                    case final text?)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: 8,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: cardSpans(
                          text,
                          blackSuit: theme.colorScheme.foreground,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
