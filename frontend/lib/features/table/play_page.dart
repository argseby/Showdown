import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../app/preferences.dart';
import '../../core/formatting.dart';
import '../../core/session_store.dart';
import '../../core/table_sounds.dart';
import '../../core/time_sync.dart';
import '../../core/turn_notifier.dart';
import '../../core/voice/voice_controller.dart';
import '../../core/ws_client.dart';
import '../../protocol/protocol.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/connection_banner.dart';
import '../../shared/top_bar.dart';
import '../admin/admin_player_actions.dart';
import '../admin/admin_widgets.dart';
import 'focus_utils.dart';
import 'shortcuts.dart';
import 'table_session.dart';
import 'widgets/action_bar.dart';
import 'widgets/invite_dialog.dart';
import 'widgets/mic_dialog.dart';
import 'widgets/say_dialog.dart';
import 'widgets/settings_tab.dart';
import 'widgets/shortcuts_overlay.dart';
import 'widgets/side_panel.dart';
import 'widgets/table_view.dart';

/// The table screen (`/t/:tableId/play`).
class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage>
    with WidgetsBindingObserver {
  final _actionBar = GlobalKey<ActionBarState>();
  final _chatFocus = FocusNode();
  final _rootFocus = FocusNode();
  PanelTab _tab = PanelTab.chat;
  bool _panelOpen = true;
  bool _panelDecided = false;
  bool _voiceRequested = false;
  bool _amountFocused = false;
  bool _windowFocused = true;
  bool _turnTitle = false;
  bool _handledTerminal = false;
  final _sounds = TableSounds.create();
  final _notifier = TurnNotifier.create();
  StreamSubscription<GameEvent>? _eventSub;
  bool _wasMyTurn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Shortcuts are handled at the hardware-keyboard level so they work no
    // matter which widget currently owns focus (see docs §10.3).
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  bool _onHardwareKey(KeyEvent event) {
    return _onKey(_rootFocus, event) == KeyEventResult.handled;
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    WidgetsBinding.instance.removeObserver(this);
    _chatFocus.dispose();
    _rootFocus.dispose();
    if (_turnTitle) _setTitle(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _windowFocused = state == AppLifecycleState.resumed;
    _updateTitle();
  }

  void _updateTitle() {
    final s = ref.read(tableSessionProvider(widget.tableId));
    final myTurn = s.isPlayer && s.snapshot?.you.options != null;
    final show = myTurn && !_windowFocused;
    if (show != _turnTitle) _setTitle(show);
  }

  void _setTitle(bool turn) {
    _turnTitle = turn;
    final l10n = context.l10n;
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: turn ? l10n.yourTurnTitle : l10n.appTitle,
      ),
    );
  }

  /// Moving costs a dead big blind next hand; the player confirms first.
  Future<void> _changeSeat(int seat) async {
    final l10n = context.l10n;
    final snap = ref.read(tableSessionProvider(widget.tableId)).snapshot;
    final bb = snap?.table.settings.bigBlind ?? 0;
    final ok = await showConfirmDialog(
      context,
      title: l10n.changeSeatTitle(seat + 1),
      body: l10n.changeSeatBody(formatChips(bb, _locale)),
      confirmLabel: l10n.changeSeatConfirm,
      cancelLabel: l10n.cancel,
    );
    if (ok && mounted) await _session.changeSeat(seat);
  }

  String get _locale => Localizations.localeOf(context).toString();

  /// What the strip above the table shows for the current snapshot.
  _PhaseInfo? _phaseStripFor(
    Snapshot snap,
    TableSessionState session,
    bool myTurn,
  ) {
    final hand = snap.hand;
    if (hand == null) {
      final next = snap.table.nextHandTs;
      if (next != null && next > 0) {
        return _PhaseInfo(kind: _PhaseKind.nextHand, deadlineTs: next);
      }
      return null;
    }
    if (hand.phase == 'showdown' || hand.phase == 'result') {
      return _PhaseInfo(
        kind: hand.phase == 'showdown'
            ? _PhaseKind.showdown
            : _PhaseKind.nextHand,
        deadlineTs: hand.phaseEndsTs,
      );
    }
    if (myTurn) {
      return _PhaseInfo(
        kind: _PhaseKind.myTurn,
        deadlineTs: hand.deadlineTs,
        timeBank: hand.timeBankActive ?? false,
      );
    }
    final seat = hand.toActSeat;
    if (seat != null) {
      final name = snap.seats
          .where((sv) => sv.seat == seat)
          .firstOrNull
          ?.player
          ?.name;
      return _PhaseInfo(
        kind: _PhaseKind.otherTurn,
        deadlineTs: hand.deadlineTs,
        name: name,
      );
    }
    return null;
  }

  VoiceController get _voiceController =>
      ref.read(voiceControllerProvider(widget.tableId).notifier);

  TableSessionNotifier get _session =>
      ref.read(tableSessionProvider(widget.tableId).notifier);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final action = shortcutFor(
      event,
      textFieldFocused:
          _amountFocused || _chatFocus.hasFocus || isTextFieldFocused(),
    );
    if (action == null) return KeyEventResult.ignored;
    final bar = _actionBar.currentState;
    switch (action) {
      case ShortcutAction.fold:
        bar?.fold();
      case ShortcutAction.checkCall:
        bar?.checkOrCall();
      case ShortcutAction.openRaise:
        bar?.openRaise();
      case ShortcutAction.selectAllIn:
        bar?.selectAllIn();
      case ShortcutAction.preset1:
        bar?.preset(0);
      case ShortcutAction.preset2:
        bar?.preset(1);
      case ShortcutAction.preset3:
        bar?.preset(2);
      case ShortcutAction.preset4:
        bar?.preset(3);
      case ShortcutAction.amountUp:
        bar?.adjust(1);
      case ShortcutAction.amountDown:
        bar?.adjust(-1);
      case ShortcutAction.amountUpBig:
        bar?.adjust(5);
      case ShortcutAction.amountDownBig:
        bar?.adjust(-5);
      case ShortcutAction.confirm:
        if (bar?.confirm() != true) return KeyEventResult.ignored;
      case ShortcutAction.cancel:
        if (isTextFieldFocused() || _chatFocus.hasFocus || _amountFocused) {
          unfocusTextField();
          _rootFocus.requestFocus();
        } else if (bar?.cancel() != true) {
          return KeyEventResult.ignored;
        }
      case ShortcutAction.focusChat:
        setState(() {
          _panelOpen = true;
          _tab = PanelTab.chat;
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _chatFocus.requestFocus(),
        );
      case ShortcutAction.toggleLog:
        _togglePanelTab(PanelTab.log);
      case ShortcutAction.toggleLeaderboard:
        _togglePanelTab(PanelTab.leaderboard);
      case ShortcutAction.toggleSound:
        ref.read(soundEnabledProvider.notifier).toggle();
      case ShortcutAction.showHelp:
        showShortcutsOverlay(context);
    }
    return KeyEventResult.handled;
  }

  void _togglePanelTab(PanelTab tab) {
    setState(() {
      if (_panelOpen && _tab == tab) {
        _panelOpen = false;
      } else {
        _panelOpen = true;
        _tab = tab;
      }
    });
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.leaveConfirmTitle,
      body: l10n.leaveConfirmBody,
      confirmLabel: l10n.leave,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _session.leave();
    await ref.read(sessionProvider(widget.tableId).notifier).clear();
    if (mounted) context.go('/t/${widget.tableId}');
  }

  Future<void> _clearAndGoToJoin() async {
    await ref.read(sessionProvider(widget.tableId).notifier).clear();
    if (mounted) context.go('/t/${widget.tableId}');
  }

  /// Leaves for the start page: players fold and free their seat first.
  Future<void> _otherTable() async {
    if (ref.read(tableSessionProvider(widget.tableId)).isPlayer) {
      final l10n = context.l10n;
      final ok = await showConfirmDialog(
        context,
        title: l10n.leaveConfirmTitle,
        body: l10n.leaveConfirmBody,
        confirmLabel: l10n.leave,
        cancelLabel: l10n.cancel,
        destructive: true,
      );
      if (!ok || !mounted) return;
      await _session.leave();
    }
    await ref.read(sessionProvider(widget.tableId).notifier).clear();
    if (mounted) context.go('/');
  }

  /// A side drawer for everything that is not play: voice chat,
  /// preferences, help and leaving.
  Future<void> _invite(BuildContext context, TableSessionState session) {
    showAdminToast(context, context.l10n.adminLinkCopied);
    return showInviteDialog(
      context,
      tableId: widget.tableId,
      snapshot: session.snapshot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final storedSession = ref.watch(sessionProvider(widget.tableId));
    final stored = storedSession.value;
    if (storedSession.hasValue && stored == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/t/${widget.tableId}');
      });
      return const Scaffold(child: SizedBox.shrink());
    }
    // The host's admin key travels with the hello; wait until it is known so
    // the socket is opened once, not twice.
    final adminTokenAsync = ref.watch(adminTokenProvider(widget.tableId));
    final adminToken = adminTokenAsync.value;
    if (stored != null && adminTokenAsync.hasValue) {
      // Never open the socket inside build: state changes would race the
      // frame. The notifier ignores repeated calls with the same tokens.
      final token = stored.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _session.start(token, adminToken: adminToken);
      });
    }

    final session = ref.watch(tableSessionProvider(widget.tableId));
    ref.listen(tableSessionProvider(widget.tableId), (prev, next) {
      _updateTitle();
      final myTurn = next.isPlayer && next.snapshot?.you.options != null;
      if (myTurn && !_wasMyTurn) {
        if (ref.read(soundEnabledProvider)) _sounds.play(SoundCue.turn);
        if (!_windowFocused && ref.read(notifyTurnProvider)) {
          _notifier.notify(
            l10n.notifyTitle,
            l10n.notifyBody(next.snapshot?.table.name ?? l10n.appTitle),
          );
          _notifier.vibrate();
        }
      }
      _wasMyTurn = myTurn;
      // Sounds for the table: cards, checks, chips and the win.
      _eventSub ??= _session.events.listen((e) {
        if (!ref.read(soundEnabledProvider)) return;
        final mySeat = ref.read(tableSessionProvider(widget.tableId)).mySeat;
        switch (e.kind) {
          case 'street_dealt':
            _sounds.play(SoundCue.deal);
          case 'hole_cards_dealt':
            if (e.seat == mySeat) _sounds.play(SoundCue.deal);
          case 'action':
            _sounds.play(e.action == 'check' ? SoundCue.check : SoundCue.chips);
          case 'blind_posted':
          case 'ante_posted':
            _sounds.play(SoundCue.chips);
          case 'pot_awarded':
            if (e.seat == mySeat) _sounds.play(SoundCue.win);
        }
      });
      if (next.connection.terminal &&
          !_handledTerminal &&
          next.connection.closeCode == CloseCodes.badToken) {
        _handledTerminal = true;
        _clearAndGoToJoin();
      }
      if (next.lastError != null &&
          next.lastError != prev?.lastError &&
          next.lastError!.code != 'muted') {
        final err = next.lastError!;
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) =>
              SurfaceCard(child: Text(_errorText(l10n, err))),
        );
      }
    });

    final snap = session.snapshot;
    final locale = Localizations.localeOf(context).toString();
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final conn = session.connection;

    String? banner;
    var bannerDestructive = false;
    Widget? bannerAction;
    if (session.serverRestarting) {
      banner = l10n.serverRestarting;
    } else if (conn.terminal && conn.closeCode == CloseCodes.replaced) {
      banner = '${l10n.replacedTitle}: ${l10n.replacedBody}';
      bannerDestructive = true;
      bannerAction = SecondaryButton(
        size: ButtonSize.small,
        onPressed: _session.reconnectNow,
        child: Text(l10n.reconnectHere),
      );
    } else if (conn.status != WsStatus.ready && conn.attempt > 0) {
      banner = l10n.connReconnecting(conn.attempt);
    } else if (conn.status == WsStatus.connecting ||
        conn.status == WsStatus.helloSent) {
      banner = l10n.connConnecting;
    }

    final myPlayer = snap == null || session.mySeat == null
        ? null
        : snap.seats.where((s) => s.seat == session.mySeat).firstOrNull?.player;

    final callbacks = ActionCallbacks(
      act: (kind, {amount}) => _session.act(kind, amount: amount),
      rebuy: _session.rebuy,
      sitOut: _session.sitOut,
      sitIn: _session.sitIn,
      showCards: (which) => _session.showCards(which),
      preAction: _session.preAction,
      rabbitHunt: _session.rabbitHunt,
      straddle: _session.setStraddle,
      runTwice: _session.runTwice,
    );
    final chipDisplay = ref.watch(chipDisplayProvider);
    final myTurn = session.isPlayer && snap?.you.options != null;
    final voice = ref.watch(voiceControllerProvider(widget.tableId));
    // The player asked for the voice chat when joining: start it once the
    // connection is up (the join click counts as the required user gesture).
    if ((stored?.voice ?? false) &&
        session.isPlayer &&
        conn.status == WsStatus.ready &&
        !_voiceRequested) {
      _voiceRequested = true;
      final muted = stored?.voiceMuted ?? false;
      final camera = stored?.voiceCamera ?? false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _voiceController.enable(muted: muted, camera: camera);
      });
    }
    ref.listen(voiceControllerProvider(widget.tableId), (prev, next) {
      if (next.hostMuted && !(prev?.hostMuted ?? false)) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) =>
              SurfaceCard(child: Text(l10n.voiceMutedByHost)),
        );
      }
      if (next.hostCameraOff && !(prev?.hostCameraOff ?? false)) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) =>
              SurfaceCard(child: Text(l10n.cameraOffByHost)),
        );
      }
      if (next.unavailable && !(prev?.unavailable ?? false)) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) =>
              SurfaceCard(child: Text(l10n.voiceUnavailable)),
        );
      }
    });

    final panel = SidePanel(
      tableId: widget.tableId,
      adminToken: adminToken,
      tab: _tab,
      onTabChanged: (t) => setState(() => _tab = t),
      chatFocusNode: _chatFocus,
      onSendChat: _session.chat,
      settings: TableSettingsTab(
        tableId: widget.tableId,
        isPlayer: session.isPlayer,
        onTakeSeat: _clearAndGoToJoin,
        onOtherTable: _otherTable,
        onLeave: session.isPlayer ? _leave : _clearAndGoToJoin,
        onShortcuts: () => showShortcutsOverlay(context),
      ),
    );

    final uiScale = ref.watch(uiScaleProvider);
    final table = Column(
      children: [
        if (banner != null)
          ConnectionBanner(
            text: banner,
            destructive: bannerDestructive,
            trailing: bannerAction,
          ),
        // The phase strip: your turn (highlighted), someone else's turn,
        // showdown, or the countdown to the next deal.
        if (snap != null && _phaseStripFor(snap, session, myTurn) != null)
          _PhaseStrip(
            key: const Key('turn-banner'),
            info: _phaseStripFor(snap, session, myTurn)!,
            winnerLines: session.winnerLines,
            chipDisplay: chipDisplay,
            bigBlind: snap.table.settings.bigBlind,
          ),
        Expanded(
          child: TableView(
            session: session,
            onTakeSeat: _changeSeat,
            speaking: voice.speaking,
            onToggleMute: voice.enabled ? _voiceController.toggleMute : null,
            onSayTap: session.isPlayer
                ? () => showSayDialog(context, ref, widget.tableId)
                : null,
            videoViews: voice.videoViews,
            onAdminTap: (snap?.you.isAdmin ?? false) && adminToken != null
                ? (p) =>
                      AdminPlayerActions(
                        ref: ref,
                        context: context,
                        tableId: widget.tableId,
                        token: adminToken,
                      ).showMenu(
                        playerId: p.id,
                        name: p.name,
                        chatMuted: p.muted ?? false,
                        voice: p.voice,
                        camera: p.camera ?? false,
                      )
                : null,
          ),
        ),
        // The accessibility scale enlarges the action bar's text and
        // buttons; cards and seats scale inside the table view.
        MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(uiScale)),
          child: ActionBar(
            key: _actionBar,
            snapshot: snap,
            callbacks: callbacks,
            isPlayer: session.isPlayer,
            myStatus: myPlayer?.status,
            chipDisplay: chipDisplay,
            shown: session.mySeat != null
                ? session.shown[session.mySeat!] ?? const []
                : const [],
            textFieldFocusChanged: (f) => _amountFocused = f,
          ),
        ),
      ],
    );

    final connDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: conn.status == WsStatus.ready
            ? const Color(0xFF43A047)
            : theme.colorScheme.destructive,
      ),
    );

    final compact = width < 700;
    if (!_panelDecided) {
      // Wide desktops open the panel; everything narrower keeps the table.
      _panelDecided = true;
      _panelOpen = width >= 1280;
    }
    // Only chat messages count on the toggle; the hand log has its own badge.
    final unread = session.unreadChat;
    final panelButton = Tooltip(
      tooltip: TooltipContainer(child: Text(l10n.panelToggle)).call,
      child: GhostButton(
        key: const Key('panel-toggle'),
        density: ButtonDensity.icon,
        onPressed: () {
          if (wide) {
            setState(() => _panelOpen = !_panelOpen);
          } else {
            _openSheet(panel);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(LucideIcons.panelRight),
            if (unread > 0 && !(wide && _panelOpen))
              Positioned(
                right: -6,
                top: -6,
                child: PrimaryBadge(
                  child: Text(unread > 99 ? '99+' : '$unread'),
                ),
              ),
          ],
        ),
      ),
    );
    final inviteButton = compact
        ? Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.invite)).call,
            child: PrimaryButton(
              key: const Key('invite'),
              density: ButtonDensity.icon,
              onPressed: () => _invite(context, session),
              child: const Icon(LucideIcons.userPlus),
            ),
          )
        : PrimaryButton(
            key: const Key('invite'),
            onPressed: () => _invite(context, session),
            leading: const Icon(LucideIcons.userPlus),
            child: Text(l10n.invite),
          );
    // The microphone button shows the voice state at a glance and opens
    // the microphone settings; the phrase button sends a quick phrase.
    final micColor = !voice.enabled
        ? theme.colorScheme.mutedForeground
        : voice.muted
        ? theme.colorScheme.destructive
        : const Color(0xFF43A047);
    final micButton = session.isPlayer
        ? Tooltip(
            tooltip: TooltipContainer(
              child: Text(
                !voice.enabled
                    ? l10n.micStateOff
                    : voice.muted
                    ? l10n.micStateMuted
                    : l10n.micStateOn,
              ),
            ).call,
            child: OutlineButton(
              key: const Key('mic-button'),
              density: ButtonDensity.icon,
              onPressed: () => showMicDialog(context, widget.tableId),
              child: Icon(
                voice.enabled && !voice.muted
                    ? LucideIcons.mic
                    : LucideIcons.micOff,
                color: micColor,
              ),
            ),
          )
        : null;
    final header = TopBar(
      compact: compact,
      showToggles: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            tooltip: TooltipContainer(
              child: Text(
                conn.status == WsStatus.ready
                    ? l10n.connConnected
                    : l10n.connDisconnected,
              ),
            ).call,
            child: connDot,
          ),
          const Gap(8),
          Flexible(
            child: Text(
              snap?.table.name ?? l10n.appTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!session.isPlayer) ...[
            const Gap(8),
            SecondaryBadge(
              child: Text(
                snap?.you.role == 'admin' ? l10n.roleAdmin : l10n.roleSpectator,
              ),
            ),
          ],
        ],
      ),
      subtitle: snap == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.blindsShort(formatChips(snap.table.settings.smallBlind, locale), formatChips(snap.table.settings.bigBlind, locale))} · ${l10n.handNumber(snap.table.handNumber)}',
                ),
                if ((snap.table.nextBlindsUpTs ?? 0) > 0) ...[
                  const Text(' · '),
                  _BlindsCountdown(target: snap.table.nextBlindsUpTs!),
                ],
              ],
            ),
      trailing: [inviteButton, const Gap(4), ?micButton, panelButton],
    );

    Widget body = wide && _panelOpen
        ? Row(
            children: [
              Expanded(child: table),
              VerticalDivider(color: theme.colorScheme.border, width: 1),
              SizedBox(
                width: width >= 1440 ? 420 : 380,
                child: Padding(padding: const EdgeInsets.all(10), child: panel),
              ),
            ],
          )
        : table;

    if (session.ended != null) {
      body = _EndedOverlay(ended: session.ended!, onBack: _clearAndGoToJoin);
    } else if (session.kicked != null) {
      body = _Notice(
        title: l10n.kickedTitle,
        body: l10n.kickedBody,
        action: l10n.backToJoin,
        onAction: _clearAndGoToJoin,
      );
    } else if (conn.terminal &&
        conn.closeCode == CloseCodes.tableGone &&
        snap == null) {
      body = _Notice(
        title: l10n.tableEndedTitle,
        body: l10n.joinTableEnded,
        action: l10n.backToJoin,
        onAction: _clearAndGoToJoin,
      );
    }

    return Focus(
      focusNode: _rootFocus,
      autofocus: true,
      child: Scaffold(headers: [header, const Divider()], child: body),
    );
  }

  void _openSheet(Widget panel) {
    openSheetOverlay<void>(
      context: context,
      position: OverlayPosition.bottom,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(padding: const EdgeInsets.all(12), child: panel),
      ),
    );
  }

  String _errorText(AppLocalizations l10n, ServerError e) {
    switch (e.code) {
      case 'not_your_turn':
        return l10n.errNotYourTurn;
      case 'illegal_action':
        return l10n.errIllegalAction;
      case 'amount_out_of_range':
        return l10n.errAmountOutOfRange;
      case 'rate_limited':
        return l10n.errRateLimited;
    }
    return l10n.errGeneric(e.message);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title).h3(),
          const Gap(8),
          Text(body).muted(),
          const Gap(16),
          PrimaryButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _EndedOverlay extends StatelessWidget {
  const _EndedOverlay({required this.ended, required this.onBack});
  final TableEnded ended;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.tableEndedTitle).h3(),
                const Gap(4),
                Text(l10n.finalStandings).muted(),
                const Gap(12),
                for (final (i, e) in ended.finalLeaderboard.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            (e.place ?? 0) > 0
                                ? l10n.placeLabel(e.place!)
                                : '${i + 1}.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if ((e.place ?? 0) == 1) ...[
                          const Icon(
                            LucideIcons.trophy,
                            size: 16,
                            color: Color(0xFFE6B422),
                          ),
                          const Gap(6),
                        ],
                        Expanded(child: Text(e.name)),
                        Text(
                          formatChips(e.stack, locale),
                          style: const TextStyle(fontFamily: 'GeistMono'),
                        ),
                        const Gap(12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            (e.net > 0 ? '+' : '') + formatChips(e.net, locale),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontFamily: 'GeistMono'),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Gap(16),
                PrimaryButton(onPressed: onBack, child: Text(l10n.backToJoin)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PhaseKind { myTurn, otherTurn, showdown, nextHand }

class _PhaseInfo {
  const _PhaseInfo({
    this.timeBank = false,
    required this.kind,
    this.deadlineTs,
    this.name,
  });
  final _PhaseKind kind;
  final int? deadlineTs;
  final String? name;
  final bool timeBank;
}

/// The strip above the table: whose turn it is and how long every phase
/// still lasts (turn, showdown, pause before the next deal).
class _PhaseStrip extends ConsumerStatefulWidget {
  const _PhaseStrip({
    super.key,
    required this.info,
    this.winnerLines = const [],
    this.chipDisplay = ChipDisplay.coins,
    this.bigBlind = 0,
  });
  final _PhaseInfo info;

  /// "name|amount|description" per awarded pot, shown during the showdown
  /// and the result phase.
  final List<String> winnerLines;
  final ChipDisplay chipDisplay;
  final int bigBlind;

  @override
  ConsumerState<_PhaseStrip> createState() => _PhaseStripState();
}

class _PhaseStripState extends ConsumerState<_PhaseStrip>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _winnerText(AppLocalizations l10n, String line, String locale) {
    final parts = line.split('|');
    final name = parts[0];
    final amount = formatAmount(
      int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      mode: widget.chipDisplay,
      bigBlind: widget.bigBlind,
      locale: locale,
    );
    final desc = parts.length > 2 ? parts[2] : '';
    return desc.isEmpty
        ? l10n.winsLine(name, amount)
        : l10n.winsLineWith(name, amount, desc);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final info = widget.info;
    final now = ref.read(timeSyncProvider.notifier).serverNow();
    final remaining = info.deadlineTs == null
        ? null
        : ((info.deadlineTs! - now) / 1000).clamp(0, 9999).ceil();
    final secs = remaining ?? 0;
    final mine = info.kind == _PhaseKind.myTurn;
    final urgent = mine && remaining != null && remaining <= 5;
    final text = switch (info.kind) {
      _PhaseKind.myTurn when info.timeBank => l10n.timeBankStrip(secs),
      _PhaseKind.myTurn =>
        remaining == null ? l10n.yourTurnBanner : l10n.yourTurnBannerTime(secs),
      _PhaseKind.otherTurn => l10n.turnOf(info.name ?? '?', secs),
      _PhaseKind.showdown => l10n.showdownStrip(secs),
      _PhaseKind.nextHand => l10n.nextHandIn(secs),
    };
    final bg = urgent
        ? theme.colorScheme.destructive
        : mine
        ? theme.colorScheme.primary
        : theme.colorScheme.muted;
    final fg = mine
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.mutedForeground;
    final showWinners =
        widget.winnerLines.isNotEmpty &&
        (info.kind == _PhaseKind.showdown || info.kind == _PhaseKind.nextHand);
    final locale = Localizations.localeOf(context).toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mine
                    ? LucideIcons.play
                    : info.kind == _PhaseKind.otherTurn
                    ? LucideIcons.hourglass
                    : LucideIcons.timer,
                size: 14,
                color: fg,
              ),
              const Gap(8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                  fontSize: mine ? 14 : 12,
                  color: fg,
                ),
              ),
            ],
          ),
          if (showWinners)
            for (final line in widget.winnerLines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  key: const Key('winner-line'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const Gap(6),
                    Flexible(
                      child: Text(
                        _winnerText(l10n, line, locale),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// "Blinds up in m:ss" driven by the server clock.
class _BlindsCountdown extends ConsumerStatefulWidget {
  const _BlindsCountdown({required this.target});
  final int target;

  @override
  ConsumerState<_BlindsCountdown> createState() => _BlindsCountdownState();
}

class _BlindsCountdownState extends ConsumerState<_BlindsCountdown>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(timeSyncProvider.notifier).serverNow();
    final secs = ((widget.target - now) / 1000).clamp(0, 359999).floor();
    final m = secs ~/ 60;
    final ss = (secs % 60).toString().padLeft(2, '0');
    return Text(context.l10n.blindsUpIn('$m:$ss'));
  }
}

/// The table's side drawer.
