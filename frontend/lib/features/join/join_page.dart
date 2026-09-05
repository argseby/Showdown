import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/formatting.dart';
import '../../core/providers.dart';
import '../../core/rest_client.dart';
import '../../core/session_store.dart';
import '../../shared/avatars.dart';
import '../../shared/display_size_picker.dart';
import '../../shared/top_bar.dart';
import '../admin/admin_session.dart';
import 'name_rules.dart';

/// Join page (`/t/:tableId`): table facts, name and password, Join / Spectate.
/// With a stored session it forwards to the table straight away.
class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends ConsumerState<JoinPage> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _adminKey = TextEditingController();
  int? _seat; // null = any free seat
  bool _voice = false;
  bool _seatsOpen = false;

  Future<void> _pickAvatar() async {
    final l10n = context.l10n;
    final picked = await showOverlay<int>(
      context,
      const DialogConfiguration(),
      builder: (context) => AlertDialog(
        title: Text(l10n.joinAvatarChange),
        content: SizedBox(
          width: 320,
          child: AvatarPicker(
            selected: _avatar,
            size: 44,
            onSelected: (i) => closeOverlay<int>(context, i),
          ),
        ),
        actions: [
          OutlineButton(
            onPressed: () => closeOverlay<int>(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    ).future;
    if (picked != null && mounted) setState(() => _avatar = picked);
  }

  int _avatar = DateTime.now().millisecondsSinceEpoch % avatarCount;
  bool _hostOpen = false;
  bool _keyBusy = false;
  String? _keyError;
  TableInfoDto? _info;
  Object? _loadError;
  bool _loading = true;
  bool _busy = false;
  String? _nameError;
  String? _passwordError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _adminKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final info = await ref.read(restClientProvider).tableInfo(widget.tableId);
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The host on another device enters the admin key; it is checked against
  /// the table before it is stored.
  Future<void> _useAdminKey() async {
    final key = _adminKey.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _keyBusy = true;
      _keyError = null;
    });
    try {
      await ref.read(adminApiProvider).getTable(key, widget.tableId);
      await ref.read(adminTokenProvider(widget.tableId).notifier).save(key);
      if (mounted) {
        setState(() {
          _hostOpen = false;
          _adminKey.clear();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _keyError = e.status == 401
              ? context.l10n.adminKeyRejected
              : context.l10n.errGeneric(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _keyError = context.l10n.errGeneric('$e'));
    } finally {
      if (mounted) setState(() => _keyBusy = false);
    }
  }

  /// Validates the form; returns the normalized name or null.
  String? _validate() {
    final l10n = context.l10n;
    final name = NameRules.normalize(_name.text);
    setState(() {
      _nameError = name == null ? l10n.joinNameInvalid : null;
      _passwordError =
          (_info?.requiresPassword ?? false) && _password.text.isEmpty
          ? l10n.joinPasswordRequired
          : null;
      _formError = null;
    });
    if (_nameError != null || _passwordError != null) return null;
    return name;
  }

  Future<void> _submit({required bool spectate}) async {
    final name = _validate();
    if (name == null) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final rest = ref.read(restClientProvider);
      final StoredSession session;
      if (spectate) {
        final r = await rest.spectate(
          widget.tableId,
          name: name,
          password: _password.text,
        );
        session = StoredSession(
          token: r.token,
          role: 'spectator',
          name: r.name,
        );
      } else {
        final r = await rest.join(
          widget.tableId,
          name: name,
          password: _password.text,
          seat: _seat,
          avatar: _avatar,
        );
        session = StoredSession(
          token: r.token,
          role: 'player',
          name: r.name,
          playerId: r.playerId,
          voice: _voice,
        );
      }
      await ref.read(sessionProvider(widget.tableId).notifier).save(session);
      if (mounted) context.go('/t/${widget.tableId}/play');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'wrong_password':
            _passwordError = l10n.errWrongPassword;
          case 'name_taken':
            _nameError = l10n.errNameTaken;
          case 'invalid_name':
            _nameError = l10n.errInvalidName;
          case 'table_full':
            _formError = l10n.errTableFull;
          case 'seat_taken':
            _formError = l10n.errSeatTaken;
            _seat = null;
            _load();
          case 'joins_closed':
            _formError = l10n.errJoinsClosed;
          case 'table_ended':
            _formError = l10n.errTableEnded;
          case 'spectators_disabled':
            _formError = l10n.errSpectatorsDisabled;
          case 'rate_limited':
            _formError = l10n.errRateLimited;
          default:
            _formError = l10n.errGeneric(e.message);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _formError = l10n.errGeneric(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final stored = ref.watch(sessionProvider(widget.tableId));
    final isHost = ref.watch(adminTokenProvider(widget.tableId)).value != null;
    if (stored.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/t/${widget.tableId}/play');
      });
    }

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      final notFound =
          _loadError is ApiException &&
          (_loadError! as ApiException).status == 404;
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notFound ? l10n.tableNotFound : l10n.joinLoadFailed).h3(),
            const Gap(16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!notFound) ...[
                  OutlineButton(onPressed: _load, child: Text(l10n.retry)),
                  const Gap(8),
                ],
                PrimaryButton(
                  onPressed: () => context.go('/'),
                  child: Text(l10n.notFoundHome),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final info = _info!;
      final state = switch (info.state) {
        'waiting' => l10n.joinStateWaiting,
        'running' => l10n.joinStateRunning,
        'paused' => l10n.joinStatePaused,
        _ => l10n.joinStateEnded,
      };
      final ended = info.state == 'ended';
      final joinsClosed =
          info.joinPolicy == 'closed' ||
          (info.joinPolicy == 'before_start' && info.state != 'waiting');
      final full = info.seated >= info.maxPlayers;
      final canJoin = !ended && !joinsClosed && !full;
      content = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(info.name).h2(),
                const Gap(4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    SecondaryBadge(child: Text(state)),
                    if (isHost)
                      PrimaryBadge(
                        key: const Key('join-host-badge'),
                        child: Text(l10n.joinHostBadge),
                      ),
                    OutlineBadge(
                      child: Text(l10n.joinSeats(info.seated, info.maxPlayers)),
                    ),
                    OutlineBadge(
                      child: Text(
                        l10n.joinBlinds(
                          formatChips(info.smallBlind, locale),
                          formatChips(info.bigBlind, locale),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.joinNameLabel).semiBold(),
                      const Gap(6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Tooltip(
                            tooltip: TooltipContainer(
                              child: Text(l10n.joinAvatarChange),
                            ).call,
                            child: GestureDetector(
                              key: const Key('join-avatar'),
                              onTap: _pickAvatar,
                              child: PlayerAvatar(index: _avatar, size: 40),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: TextField(
                              key: const Key('join-name'),
                              controller: _name,
                              placeholder: Text(l10n.joinNamePlaceholder),
                              autofocus: true,
                              maxLength: 20,
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                              onSubmitted: (_) =>
                                  canJoin ? _submit(spectate: false) : null,
                            ),
                          ),
                        ],
                      ),
                      if (_nameError != null) ...[
                        const Gap(4),
                        Text(
                          _nameError!,
                          key: const Key('join-name-error'),
                          style: TextStyle(
                            color: theme.colorScheme.destructive,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (canJoin) ...[
                        const Gap(10),
                        GhostButton(
                          key: const Key('join-seats-toggle'),
                          size: ButtonSize.small,
                          alignment: Alignment.centerLeft,
                          onPressed: () =>
                              setState(() => _seatsOpen = !_seatsOpen),
                          leading: Icon(
                            _seatsOpen
                                ? LucideIcons.chevronDown
                                : LucideIcons.chevronRight,
                          ),
                          child: Text(
                            _seat == null
                                ? l10n.joinPickSeat
                                : '${l10n.joinSeatLabel} ${_seat! + 1}',
                          ),
                        ),
                        if (_seatsOpen) ...[
                          const Gap(6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _seat == null
                                  ? PrimaryButton(
                                      key: const Key('seat-any'),
                                      size: ButtonSize.small,
                                      onPressed: () {},
                                      child: Text(l10n.joinSeatAny),
                                    )
                                  : OutlineButton(
                                      key: const Key('seat-any'),
                                      size: ButtonSize.small,
                                      onPressed: () =>
                                          setState(() => _seat = null),
                                      child: Text(l10n.joinSeatAny),
                                    ),
                              for (var i = 0; i < info.maxPlayers; i++)
                                if (info.takenSeats.contains(i))
                                  OutlineButton(
                                    key: Key('seat-$i'),
                                    size: ButtonSize.small,
                                    onPressed: null,
                                    child: Text('${i + 1}'),
                                  )
                                else if (_seat == i)
                                  PrimaryButton(
                                    key: Key('seat-$i'),
                                    size: ButtonSize.small,
                                    onPressed: () {},
                                    child: Text('${i + 1}'),
                                  )
                                else
                                  OutlineButton(
                                    key: Key('seat-$i'),
                                    size: ButtonSize.small,
                                    onPressed: () => setState(() => _seat = i),
                                    child: Text('${i + 1}'),
                                  ),
                            ],
                          ),
                        ],
                      ],
                      if (info.requiresPassword) ...[
                        const Gap(12),
                        Text(l10n.joinPasswordLabel).semiBold(),
                        const Gap(6),
                        TextField(
                          key: const Key('join-password'),
                          controller: _password,
                          obscureText: true,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                          onSubmitted: (_) =>
                              canJoin ? _submit(spectate: false) : null,
                        ),
                        if (_passwordError != null) ...[
                          const Gap(4),
                          Text(
                            _passwordError!,
                            key: const Key('join-password-error'),
                            style: TextStyle(
                              color: theme.colorScheme.destructive,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                      if (ended) ...[
                        const Gap(12),
                        Text(l10n.joinTableEnded).muted(),
                      ],
                      if (!ended && joinsClosed) ...[
                        const Gap(12),
                        Text(l10n.joinClosed).muted(),
                      ],
                      if (!ended && !joinsClosed && full) ...[
                        const Gap(12),
                        Text(l10n.errTableFull).muted(),
                      ],
                      if (_formError != null) ...[
                        const Gap(12),
                        Text(
                          _formError!,
                          key: const Key('join-form-error'),
                          style: TextStyle(
                            color: theme.colorScheme.destructive,
                          ),
                        ),
                      ],
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              key: const Key('join-submit'),
                              onPressed: canJoin && !_busy
                                  ? () => _submit(spectate: false)
                                  : null,
                              leading: const Icon(LucideIcons.armchair),
                              child: Text(l10n.joinButton),
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: OutlineButton(
                              key: const Key('join-spectate'),
                              onPressed:
                                  info.allowSpectators && !ended && !_busy
                                  ? () => _submit(spectate: true)
                                  : null,
                              leading: const Icon(LucideIcons.eye),
                              child: Text(l10n.spectateButton),
                            ),
                          ),
                        ],
                      ),
                      if (!info.allowSpectators) ...[
                        const Gap(8),
                        Text(l10n.joinSpectatorsOff).muted().small(),
                      ],
                    ],
                  ),
                ),
                if (canJoin) ...[
                  const Gap(12),
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.headphones,
                              size: 18,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const Gap(8),
                            Expanded(child: Text(l10n.voiceTitle).semiBold()),
                            Switch(
                              key: const Key('join-voice'),
                              value: _voice,
                              onChanged: (v) => setState(() => _voice = v),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(l10n.voiceJoinHint).muted().small(),
                      ],
                    ),
                  ),
                ],
                const Gap(12),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.zoomIn,
                            size: 18,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          const Gap(8),
                          Expanded(child: Text(l10n.displaySize).semiBold()),
                        ],
                      ),
                      const Gap(4),
                      Text(l10n.displaySizeHint).muted().small(),
                      const Gap(8),
                      const DisplaySizePicker(),
                    ],
                  ),
                ),
                if (!isHost && !ended) ...[
                  const Gap(12),
                  if (!_hostOpen)
                    GhostButton(
                      key: const Key('join-host-toggle'),
                      onPressed: () => setState(() => _hostOpen = true),
                      leading: const Icon(LucideIcons.key),
                      child: Text(l10n.joinHostEnter),
                    )
                  else
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.adminKey).semiBold(),
                          const Gap(6),
                          TextField(
                            key: const Key('join-host-key'),
                            controller: _adminKey,
                            obscureText: true,
                            onSubmitted: (_) => _useAdminKey(),
                          ),
                          if (_keyError != null) ...[
                            const Gap(4),
                            Text(
                              _keyError!,
                              key: const Key('join-host-error'),
                              style: TextStyle(
                                color: theme.colorScheme.destructive,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const Gap(10),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  key: const Key('join-host-use'),
                                  onPressed: _keyBusy ? null : _useAdminKey,
                                  child: Text(l10n.joinHostUse),
                                ),
                              ),
                              const Gap(8),
                              OutlineButton(
                                onPressed: () =>
                                    setState(() => _hostOpen = false),
                                child: Text(l10n.cancel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      headers: [
        TopBar(
          title: Text(l10n.joinTitle),
          leading: [
            Tooltip(
              tooltip: TooltipContainer(child: Text(l10n.notFoundHome)).call,
              child: GhostButton(
                key: const Key('join-home'),
                density: ButtonDensity.icon,
                onPressed: () => context.go('/'),
                child: const Icon(LucideIcons.house),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
      child: content,
    );
  }
}
