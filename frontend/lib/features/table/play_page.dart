import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../app/preferences.dart';
import '../../core/formatting.dart';
import '../../core/gamepad/gamepad.dart';
import '../../core/gamepad/pad_navigation.dart';
import '../../core/gamepad/pad_section.dart';
import '../../core/peer_prefs.dart';
import '../../core/providers.dart';
import '../../core/session_store.dart';
import '../../core/table_sounds.dart';
import '../../core/time_sync.dart';
import '../../core/turn_notifier.dart';
import '../../core/voice/voice_controller.dart';
import '../../core/voice/voice_engine.dart';
import '../../core/ws_client.dart';
import '../../protocol/protocol.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/connection_banner.dart';
import '../../shared/top_bar.dart';
import '../admin/admin_player_actions.dart';
import '../admin/admin_session.dart';
import '../admin/admin_widgets.dart';
import 'drawing.dart';
import 'focus_utils.dart';
import 'network_texts.dart';
import 'replay/replay_dialog.dart';
import 'shortcuts.dart';
import 'table_session.dart';
import 'widgets/action_bar.dart';
import 'widgets/invite_dialog.dart';
import 'widgets/pad_hint_bar.dart';
import 'widgets/player_menu.dart';
import 'widgets/say_dialog.dart';
import 'widgets/self_menu.dart';
import 'widgets/settings_tab.dart';
import 'widgets/shortcuts_overlay.dart';
import 'widgets/side_panel.dart';
import 'widgets/table_rules_dialog.dart';
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
  PanelTab _tab = PanelTab.settings;
  bool _panelOpen = true;
  bool _panelDecided = false;
  bool _voiceRequested = false;

  /// Peers whose failed audio link was already explained in a toast.
  final _failedToasted = <String>{};
  bool _amountFocused = false;
  bool _windowFocused = true;
  bool _turnTitle = false;
  bool _handledTerminal = false;
  final _sounds = TableSounds.create();
  final _notifier = TurnNotifier.create();
  StreamSubscription<GameEvent>? _eventSub;
  StreamSubscription<PadButton>? _padSub;

  /// The preset the controller's ← → last picked in the raise control.
  int _padPreset = -1;

  /// From the last build: the wide layout, and the side panel widget (the
  /// controller's Back opens it as a sheet on narrow screens).
  bool _wide = false;
  Widget? _panelWidget;
  final _sidePanel = GlobalKey<SidePanelState>();

  /// The controller cursor (section, dialog, legend) is recomputed between
  /// frames, never while building: the tree walk would touch widgets on
  /// their way out. Published through [padCursorProvider].
  bool _padRefreshPending = false;

  /// False between deactivate() and dispose(): the state object is still
  /// "mounted" there, but its element has left the tree and reading a
  /// provider through `ref` throws. The post-frame callbacks below outlive
  /// a route change, so they have to check this and not just `mounted`.
  bool _attached = true;
  bool _wasMyTurn = false;

  @override
  void initState() {
    super.initState();
    _peerPrefs = ref.read(peerPrefsProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    // Shortcuts are handled at the hardware-keyboard level so they work no
    // matter which widget currently owns focus (see docs §10.3).
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    // A controller, when the browser has one: same actions as the keys.
    final pad = ref.read(gamepadProvider.notifier)..start();
    _padSub = pad.presses.listen(_onPad);
    FocusManager.instance.addListener(_onFocusChange);
  }

  void _onFocusChange() => _refreshPadContext();

  /// Recomputes the cursor's context after the current frame.
  void _refreshPadContext() {
    if (_padRefreshPending || !mounted || !_attached) return;
    _padRefreshPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _padRefreshPending = false;
      if (!mounted || !_attached || !ref.read(gamepadProvider)) return;
      final focus = FocusManager.instance.primaryFocus;
      final section = _sectionOf(focus);
      final dialog = _overlayControl() != null;
      final (where, legend) = _padLegend(context.l10n, section, dialog);
      reportPadDebug('${section?.name} dialog=$dialog ${_describe(focus)}');
      ref
          .read(padCursorProvider.notifier)
          .set(
            PadCursor(
              section: section,
              dialog: dialog,
              where: where,
              legend: legend,
            ),
          );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _onHardwareKey(KeyEvent event) {
    return _onKey(_rootFocus, event) == KeyEventResult.handled;
  }

  /// Held from initState: ref may not be used in dispose.
  late final PeerPrefsNotifier _peerPrefs;

  @override
  void deactivate() {
    _attached = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _attached = true;
  }

  @override
  void dispose() {
    // Per-player choices (volume, hidden video, ...) last one visit. The
    // reset cannot happen inside dispose — Riverpod forbids writing to a
    // provider from a widget life-cycle — so it goes out with the frame.
    final peerPrefs = _peerPrefs;
    scheduleMicrotask(peerPrefs.clear);
    _eventSub?.cancel();
    _padSub?.cancel();
    FocusManager.instance.removeListener(_onFocusChange);
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _holdTimer?.cancel();
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

  /// What the strip above the table shows for the current snapshot. There
  /// is always something, so the strip never changes height.
  _PhaseInfo _phaseStripFor(
    Snapshot snap,
    TableSessionState session,
    bool myTurn,
    AppLocalizations l10n,
  ) {
    final hand = snap.hand;
    if (hand == null) {
      final next = snap.table.nextHandTs;
      if (next != null && next > 0) {
        return _PhaseInfo(kind: _PhaseKind.nextHand, deadlineTs: next);
      }
      return _PhaseInfo(
        kind: _PhaseKind.idle,
        name: switch (snap.table.state) {
          'paused' => l10n.tablePaused,
          'waiting' => l10n.tableWaiting,
          // An ended table can be looked at (and restarted): say what it is
          // rather than leaving it looking like a table about to deal.
          'ended' => l10n.tableEndedTitle,
          _ => l10n.waitingForPlayers,
        },
      );
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
    return const _PhaseInfo(kind: _PhaseKind.idle, name: '');
  }

  /// Opens the hand replay with the viewer's session (or the admin key).
  Future<void> _replay() async {
    final session = ref.read(tableSessionProvider(widget.tableId));
    final stored = ref.read(sessionProvider(widget.tableId)).value;
    final adminToken = ref.read(adminTokenProvider(widget.tableId)).value;
    final token = adminToken ?? stored?.token;
    final snapshot = session.snapshot;
    if (token == null || snapshot == null) return;
    await showReplayDialog(
      context,
      tableId: widget.tableId,
      token: token,
      admin: adminToken != null && stored == null,
      base: snapshot,
      viewerSeat: session.mySeat,
    );
  }

  VoiceController get _voiceController =>
      ref.read(voiceControllerProvider(widget.tableId).notifier);

  TableSessionNotifier get _session =>
      ref.read(tableSessionProvider(widget.tableId).notifier);

  /// The hold shortcut whose key is down, the key itself and the timer that
  /// fires it; the action bar fills the key cap while this runs.
  ShortcutAction? _holdAction;
  LogicalKeyboardKey? _holdKey;
  Timer? _holdTimer;

  void _startHold(ShortcutAction action, LogicalKeyboardKey key) {
    if (_holdAction == action) return; // auto-repeat while already holding
    _holdTimer?.cancel();
    setState(() {
      _holdAction = action;
      _holdKey = key;
    });
    _holdTimer = Timer(shortcutHoldDuration, () {
      final held = _holdAction;
      _cancelHold();
      if (held != null) _runShortcut(held);
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_holdAction == null || !mounted) return;
    setState(() {
      _holdAction = null;
      _holdKey = null;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Hold shortcuts: letting go of the key (or of Shift) before the cap
    // has filled calls the whole thing off.
    if (event is KeyUpEvent) {
      if (_holdAction == null) return KeyEventResult.ignored;
      final key = event.logicalKey;
      if (key == _holdKey ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        _cancelHold();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent) {
      return _holdAction != null
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    final action = shortcutFor(
      event,
      textFieldFocused:
          _amountFocused || _chatFocus.hasFocus || isTextFieldFocused(),
    );
    if (action == null) return KeyEventResult.ignored;
    if (shortcutHolds(action)) {
      _startHold(action, event.logicalKey);
      return KeyEventResult.handled;
    }
    return _runShortcut(action);
  }

  /// Runs a shortcut; hold shortcuts arrive here once their time is up.
  KeyEventResult _runShortcut(ShortcutAction action) {
    final bar = _actionBar.currentState;
    switch (action) {
      case ShortcutAction.fold:
        bar?.fold();
      case ShortcutAction.checkCall:
        bar?.checkOrCall();
      case ShortcutAction.openRaise:
        bar?.openRaise(focusInput: false);
      case ShortcutAction.focusAmount:
        bar?.focusAmount();
      case ShortcutAction.selectAllIn:
        bar?.selectAllIn();
      case ShortcutAction.showFirst:
        bar?.showCards('first');
      case ShortcutAction.showSecond:
        bar?.showCards('second');
      case ShortcutAction.showBoth:
        bar?.showCards('both');
      case ShortcutAction.rabbitHunt:
        bar?.rabbitHunt();
      case ShortcutAction.preCheckFold:
        bar?.preAction('check_fold');
      case ShortcutAction.preCallAny:
        bar?.preAction('call_any');
      case ShortcutAction.sitOut:
        bar?.toggleSitOut();
      case ShortcutAction.rebuy:
        bar?.rebuy();
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

  /// A controller button. At the table the buttons are the table actions;
  /// once a control has focus (the D-pad moved there, or a dialog is
  /// open) A activates it, B closes the dialog or drops the focus, and
  /// the directions move between controls.
  void _onPad(PadButton b) {
    if (!mounted) return;
    _refreshPadContext();
    final bar = _actionBar.currentState;
    final raise = bar?.raiseOpen ?? false;
    final focus = FocusManager.instance.primaryFocus;
    final control =
        focus != null && focus != _rootFocus && focus is! FocusScopeNode
        ? focus
        : null;
    final controlCtx = control?.context;
    // Something inside a dialog or sheet: the focused control when it is
    // in one, else the topmost overlay's first control.
    final overlayCtx =
        controlCtx != null &&
            Data.maybeFind<OverlayCompleter<dynamic>>(controlCtx) != null
        ? controlCtx
        : _overlayControl()?.context;
    final inRaise = raise && control == null && overlayCtx == null;
    switch (b) {
      case PadButton.a:
        // Untyped lookup: shadcn registers a CallbackAction<Intent>, which
        // the typed one refuses (flutter/flutter#180871).
        const activate = ActivateIntent();
        if (controlCtx != null &&
            Actions.maybeFind<Intent>(controlCtx, intent: activate) != null) {
          // The control may vanish (a settings page opens, a tab changes):
          // keep the cursor in its section, or move into a dialog it opened.
          final section = _sectionOf(control);
          Actions.invoke(controlCtx, activate);
          if (section != null) _restoreSoon(section);
        } else if (overlayCtx == null) {
          raise ? bar?.confirm() : bar?.checkOrCall();
        }
      case PadButton.b:
        // In the panel a settings page goes back first, also when the
        // panel is a sheet on a phone (which is an overlay itself).
        if (_sectionOf(control) == PadSection.panel &&
            (_sidePanel.currentState?.back() ?? false)) {
          _restoreSoon(PadSection.panel);
        } else if (overlayCtx != null) {
          closeOverlay<void>(overlayCtx);
        } else if (raise) {
          bar?.cancel();
        } else if (control != null && _sectionOf(control) != PadSection.panel) {
          // Drop the cursor at the table; in the panel's menu it stays
          // (Back is the way out), so B never throws players out.
          control.unfocus();
          _rootFocus.requestFocus();
        }
      case PadButton.x:
        if (overlayCtx == null) bar?.fold();
      case PadButton.y:
        if (overlayCtx == null) bar?.openRaise(focusInput: false);
      case PadButton.rt:
        _cycleTab(1);
      case PadButton.lt:
        _cycleTab(-1);
      case PadButton.lb:
        inRaise ? bar?.adjust(-5) : _cycleSection(-1);
      case PadButton.rb:
        inRaise ? bar?.adjust(5) : _cycleSection(1);
      case PadButton.back:
        _togglePanelFocus(overlayCtx);
      case PadButton.start:
        showShortcutsOverlay(context);
      case PadButton.up:
        inRaise ? bar?.adjust(1) : _moveFocus(TraversalDirection.up);
      case PadButton.down:
        inRaise ? bar?.adjust(-1) : _moveFocus(TraversalDirection.down);
      case PadButton.left:
        inRaise ? _cyclePreset(-1) : _moveFocus(TraversalDirection.left);
      case PadButton.right:
        inRaise ? _cyclePreset(1) : _moveFocus(TraversalDirection.right);
      case PadButton.l3:
      case PadButton.r3:
        break;
    }
  }

  /// LT / RT inside the panel: the previous or next tab, cursor kept.
  void _cycleTab(int delta) {
    const tabs = PanelTab.values;
    final next = tabs[(tabs.indexOf(_tab) + delta) % tabs.length];
    final panel = _sidePanel.currentState;
    if (panel != null) {
      panel.selectTab(next);
    } else {
      setState(() => _tab = next);
    }
    if (_sectionOf(FocusManager.instance.primaryFocus) == PadSection.panel) {
      // The cursor follows the active tab (its node stays, the content
      // under it changes).
      _focusSectionSoon(PadSection.panel);
    } else {
      // From the table: the triggers are the way into the panel too. The
      // sheet is opened after the rebuild, so it carries the new tab.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterPanel();
      });
    }
  }

  /// Opens the panel when it is closed and puts the cursor into it.
  void _enterPanel() {
    if (_wide) {
      if (!_panelOpen) setState(() => _panelOpen = true);
    } else if (_panelWidget != null && _overlayControl() == null) {
      _openSheet(_panelWidget!);
    }
    _focusSectionSoon(PadSection.panel);
  }

  /// After the focused control disappeared: the cursor goes into a dialog
  /// that just opened, else back to the top of [section].
  void _restoreSoon(PadSection section, [int tries = 4]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final f = FocusManager.instance.primaryFocus;
      if (f != null && f != _rootFocus && f is! FocusScopeNode) return;
      final node = _overlayControl() ?? _landing(section);
      if (node != null) {
        node.requestFocus();
      } else if (tries > 0) {
        _restoreSoon(section, tries - 1);
      }
    });
  }

  /// The legend for the controller: where the cursor is and what the
  /// buttons do there.
  (String, List<PadLegendItem>) _padLegend(
    AppLocalizations l10n,
    PadSection? section,
    bool dialog,
  ) {
    final raise = _actionBar.currentState?.raiseOpen ?? false;
    const move = '↑ ↓ ← →';
    // The panel as a sheet on phones is an overlay too, but it is the panel.
    if (dialog && section != PadSection.panel) {
      return (
        l10n.padWhereDialog,
        [(move, l10n.padMove), ('A', l10n.padSelect), ('B', l10n.padClose)],
      );
    }
    switch (section) {
      case PadSection.panel:
        final tab = switch (_tab) {
          PanelTab.chat => l10n.tabChat,
          PanelTab.log => l10n.tabLog,
          PanelTab.leaderboard => l10n.tabLeaderboard,
          PanelTab.settings => l10n.tabSettings,
        };
        final page = _sidePanel.currentState?.pageTitle(l10n);
        return (
          [l10n.padWherePanel, tab, ?page].join(' · '),
          [
            ('LT RT', l10n.padTab),
            (move, l10n.padMove),
            ('A', l10n.padSelect),
            ('B', l10n.padBack),
            ('Back', l10n.padClose),
            ('LB RB', l10n.padSection),
          ],
        );
      case PadSection.table:
        return (
          l10n.padWhereTable,
          [
            (move, l10n.padMove),
            ('A', l10n.padOpen),
            ('B', l10n.padBack),
            ('LT RT', l10n.padTab),
            ('Back', l10n.padPanel),
          ],
        );
      case PadSection.actions:
      case null:
        if (raise) {
          return (
            l10n.padWhereActions,
            [
              ('↑ ↓', l10n.padAmount),
              ('← →', l10n.padPreset),
              ('LB RB', l10n.padFive),
              ('A', l10n.padConfirm),
              ('B', l10n.padCancel),
            ],
          );
        }
        return (
          l10n.padWhereActions,
          [
            ('X', l10n.fold),
            ('A', l10n.scCheckCall),
            ('Y', l10n.raise),
            (move, l10n.padMove),
            ('LT RT', l10n.padTab),
            ('Back', l10n.padPanel),
            ('Start', l10n.padHelp),
          ],
        );
    }
  }

  /// ← → in the raise control: min, ½ pot, ¾ pot, pot, all-in.
  void _cyclePreset(int delta) {
    _padPreset = (_padPreset + delta).clamp(0, 4);
    _padPreset == 4
        ? _actionBar.currentState?.selectAllIn()
        : _actionBar.currentState?.preset(_padPreset);
  }

  /// Moves focus with the D-pad. With nothing focused yet it starts in the
  /// open dialog, else in the action bar, the table, the panel.
  void _moveFocus(TraversalDirection direction) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus == _rootFocus || focus is FocusScopeNode) {
      final start =
          _overlayControl() ??
          _sectionControl(PadSection.actions) ??
          _sectionControl(PadSection.table) ??
          _sectionControl(PadSection.panel) ??
          _controls().firstOrNull;
      start?.requestFocus();
      return;
    }
    // First among the controls of the same dialog, sheet or section (a
    // seat behind an open sheet must not catch it); with nothing left
    // there, across into the neighbouring section, so the D-pad alone
    // reaches the panel from the table and back.
    final from = _rectOf(focus);
    if (from == null) return;
    int? pick(Iterable<FocusNode> nodes, List<FocusNode> into) {
      into.clear();
      final rects = <Rect>[];
      for (final n in nodes) {
        final r = _rectOf(n);
        if (r == null) continue;
        into.add(n);
        rects.add(r);
      }
      return padNeighbour(from, rects, direction);
    }

    final candidates = <FocusNode>[];
    var i = pick(_neighbours(focus), candidates);
    // Sideways only: the panel sits beside the table. Up and down stay
    // put, so a tab without controls below it does not spill the cursor
    // onto the seats.
    final sideways =
        direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    if (i == null && sideways && !_inOverlay(focus)) {
      i = pick(
        _controls().where((n) => n != focus && !_inOverlay(n)),
        candidates,
      );
    }
    if (i == null) return;
    final target = candidates[i];
    reportPadDebug(
      'move $direction -> ${_describe(target)} ${_rectOf(target)} '
      'section=${_sectionOf(target)?.name} '
      'canRequestFocus=${target.canRequestFocus} '
      'widget=${target.context?.widget.runtimeType}',
    );
    target.requestFocus();
    Scrollable.ensureVisible(
      target.context!,
      alignment: 0.5,
      duration: const Duration(milliseconds: 150),
    );
  }

  /// The focused control for the debug hook: the nearest keyed ancestor.
  String _describe(FocusNode? node) {
    if (node == null || node == _rootFocus) return 'none';
    if (node is FocusScopeNode) return 'scope';
    String? key;
    node.context?.visitAncestorElements((e) {
      if (e.widget.key != null) {
        key = '${e.widget.runtimeType}${e.widget.key}';
        return false;
      }
      return true;
    });
    return key ?? '${node.context?.widget.runtimeType}';
  }

  bool _inOverlay(FocusNode node) =>
      Data.maybeFind<OverlayCompleter<dynamic>>(node.context!) != null;

  /// The controls the cursor may move to from [node]: those in the same
  /// dialog or sheet, else those in the same section outside any overlay.
  Iterable<FocusNode> _neighbours(FocusNode node) {
    final ctx = node.context!;
    final overlay = Data.maybeFind<OverlayCompleter<dynamic>>(ctx);
    final section = PadSectionScope.of(ctx);
    return _controls().where((n) {
      if (n == node) return false;
      final o = Data.maybeFind<OverlayCompleter<dynamic>>(n.context!);
      if (overlay != null) return identical(o, overlay);
      return o == null && PadSectionScope.of(n.context!) == section;
    });
  }

  /// Every focusable control on screen. Dialogs and sheets live in the
  /// app's overlay, outside this page's scope, so the root scope it is.
  /// The page's own root node is a focusable too (it catches the keys),
  /// and its box is the whole screen: never a cursor target. Other
  /// screen-sized nodes (the app's key handlers) are dropped by [_rectOf].
  Iterable<FocusNode> _controls() => [
    for (final n in FocusManager.instance.rootScope.traversalDescendants)
      if (n is! FocusScopeNode && n != _rootFocus && n.context != null) n,
  ];

  /// Where [node] is on screen; null for a node whose box is not laid
  /// out or has no size (FocusNode.rect would throw on it), which is not
  /// something the cursor can reach anyway.
  Rect? _rectOf(FocusNode node) {
    final box = node.context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (box.size.isEmpty) return null;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    if (rect.isEmpty) return null;
    // A node the size of the screen is a key handler, not a control.
    final screen = MediaQuery.sizeOf(context);
    if (rect.width * rect.height > 0.5 * screen.width * screen.height) {
      return null;
    }
    return rect;
  }

  /// The top-left one of [nodes].
  FocusNode? _topLeft(Iterable<FocusNode> nodes) {
    FocusNode? best;
    Rect? bestRect;
    for (final n in nodes) {
      final r = _rectOf(n);
      if (r == null) continue;
      if (bestRect == null ||
          r.top < bestRect.top ||
          (r.top == bestRect.top && r.left < bestRect.left)) {
        best = n;
        bestRect = r;
      }
    }
    return best;
  }

  /// The top-left control inside an open dialog or sheet, if any is open.
  FocusNode? _overlayControl() => _topLeft(
    _controls().where(
      (n) => Data.maybeFind<OverlayCompleter<dynamic>>(n.context!) != null,
    ),
  );

  /// Where the cursor lands when it enters or returns to [section]: in
  /// the panel the active tab (its strip is the panel's constant), else
  /// the section's top-left control.
  FocusNode? _landing(PadSection section) {
    if (section == PadSection.panel) {
      // Only while the strip is on screen (a settings page hides it): a
      // node keeps a stale context after its widget is gone.
      final tab = _sidePanel.currentState?.tabNode(_tab);
      if (tab != null && _controls().contains(tab) && _rectOf(tab) != null) {
        return tab;
      }
    }
    return _sectionControl(section);
  }

  /// The top-left control of [section], null when it has none on screen.
  FocusNode? _sectionControl(PadSection section) => _topLeft(
    _controls().where((n) => PadSectionScope.of(n.context!) == section),
  );

  PadSection? _sectionOf(FocusNode? node) {
    final ctx = node?.context;
    return ctx == null ? null : PadSectionScope.of(ctx);
  }

  static const _sections = [
    PadSection.actions,
    PadSection.table,
    PadSection.panel,
  ];

  /// LB / RB: the previous or next section that has controls on screen.
  /// Nothing while a dialog or sheet is open: the sections are behind it.
  void _cycleSection(int delta) {
    if (_overlayControl() != null) return;
    final current = _sectionOf(FocusManager.instance.primaryFocus);
    var i = current == null ? (delta > 0 ? -1 : 0) : _sections.indexOf(current);
    for (var n = 0; n < _sections.length; n++) {
      i = (i + delta) % _sections.length;
      if (i < 0) i += _sections.length;
      final node = _sectionControl(_sections[i]);
      if (node != null) {
        node.requestFocus();
        return;
      }
    }
  }

  /// Focuses [section] once it is on screen (a panel or sheet that is
  /// still opening), giving up after a few frames.
  void _focusSectionSoon(PadSection section, [int tries = 8]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _landing(section);
      if (node != null) {
        node.requestFocus();
      } else if (tries > 0) {
        _focusSectionSoon(section, tries - 1);
      }
    });
  }

  /// Back: into the side panel (opening it when closed), and from the
  /// panel back out to the action bar (closing it again).
  void _togglePanelFocus(BuildContext? overlayCtx) {
    if (_sectionOf(FocusManager.instance.primaryFocus) == PadSection.panel) {
      if (overlayCtx != null) {
        closeOverlay<void>(overlayCtx);
      } else if (_wide) {
        setState(() => _panelOpen = false);
      }
      _focusSectionSoon(PadSection.actions);
      return;
    }
    _enterPanel();
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

  /// Host: open a new round on this table (same id, same seats, same link).
  Future<void> _newRound() async {
    final l10n = context.l10n;
    final token = ref.read(adminTokenProvider(widget.tableId)).value;
    if (token == null) return;
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminNewRoundTitle,
      body: l10n.adminNewRoundBody,
      confirmLabel: l10n.adminNewRoundStart,
      cancelLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    final state = await guardAdmin(
      ref,
      context,
      widget.tableId,
      () => ref
          .read(adminApiProvider)
          .lifecycle(token, widget.tableId, 'restart'),
    );
    if (state != null && mounted) {
      showAdminToast(context, l10n.adminNewRoundDone);
    }
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

  /// The rules card again, from the Settings tab.
  void _showRules() {
    final snap = ref.read(tableSessionProvider(widget.tableId)).snapshot;
    if (snap != null) showTableRulesDialog(context, snapshot: snap);
  }

  /// A side drawer for everything that is not play: voice chat,
  /// preferences, help and leaving.
  Future<void> _invite(BuildContext context, TableSessionState session) {
    showAdminToast(context, context.l10n.adminLinkCopied);
    // The host, and only the host, can fill a seat with a bot from here.
    final adminToken = ref.read(adminTokenProvider(widget.tableId)).value;
    return showInviteDialog(
      context,
      tableId: widget.tableId,
      snapshot: session.snapshot,
      adminToken: (session.snapshot?.you.isAdmin ?? false) ? adminToken : null,
    );
  }

  /// Display name of a player at the table, or the id when unknown.
  String _playerName(String id) {
    final snap = ref.read(tableSessionProvider(widget.tableId)).snapshot;
    for (final sv in snap?.seats ?? const <SeatView>[]) {
      if (sv.player?.id == id) return sv.player!.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final storedSession = ref.watch(sessionProvider(widget.tableId));
    final stored = storedSession.value;
    // No session, or one that could not be read at all: the join page is the
    // only place the player can do anything about it. Staying here would
    // show a table this page never connects to.
    if (storedSession.hasError || (storedSession.hasValue && stored == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/t/${widget.tableId}');
      });
      return const Scaffold(child: SizedBox.shrink());
    }
    // The host's admin key travels with the hello; wait until it is known so
    // the socket is opened once, not twice. A key that cannot be read is not
    // worth stranding a player for — connect as an ordinary one instead.
    final adminTokenAsync = ref.watch(adminTokenProvider(widget.tableId));
    final adminToken = adminTokenAsync.value;
    if (stored != null && (adminTokenAsync.hasValue || adminTokenAsync.hasError)) {
      // Never open the socket inside build: state changes would race the
      // frame. The notifier ignores repeated calls with the same tokens.
      final token = stored.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _session.start(token, adminToken: adminToken);
      });
    }

    final session = ref.watch(tableSessionProvider(widget.tableId));
    ref.listen(gamepadProvider, (prev, next) {
      if (next && prev != true) {
        showAdminToast(
          context,
          l10n.padConnected(ref.read(padInfoProvider)?.id ?? ''),
        );
      }
    });
    ref.listen(tableSessionProvider(widget.tableId), (prev, next) {
      _updateTitle();
      // Fresh from the join page: the table rules, once the first snapshot
      // is in (and only then; a reload does not repeat it).
      final snap = next.snapshot;
      if (snap != null &&
          prev?.snapshot == null &&
          ref.read(justJoinedProvider) == widget.tableId) {
        ref.read(justJoinedProvider.notifier).clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showTableRulesDialog(context, snapshot: snap);
        });
      }
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
      if (next.cameraUnavailable &&
          !(prev?.cameraUnavailable ?? false) &&
          next.cameraError != null) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) => SurfaceCard(
            child: Text('${l10n.cameraUnavailable} ${next.cameraError}'),
          ),
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
      // The network check says voice and video will not reach other
      // networks from here: say so once, with what to do about it.
      final report = next.network;
      final isHost =
          ref
              .read(tableSessionProvider(widget.tableId))
              .snapshot
              ?.you
              .isAdmin ??
          false;
      if (report != null && report != prev?.network && report.problem) {
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) => SurfaceCard(
            child: Text(networkExplanation(l10n, report, host: isHost)),
          ),
        );
      }
      // A peer's audio link failed: name the peer and the likely reason.
      if (!next.enabled) _failedToasted.clear();
      for (final id in next.failed.difference(prev?.failed ?? const {})) {
        if (!_failedToasted.add(id)) continue;
        final reason = report != null && report.problem
            ? networkExplanation(l10n, report, host: isHost)
            : l10n.networkPeerNoRoute;
        showToast(
          context: context,
          location: ToastLocation.bottomCenter,
          builder: (context, overlay) => SurfaceCard(
            child: Text('${l10n.voicePeerFailed(_playerName(id))} $reason'),
          ),
        );
      }
    });

    _wide = wide;
    final panel = PadSectionScope(
      section: PadSection.panel,
      child: SidePanel(
        key: _sidePanel,
        tableId: widget.tableId,
        adminToken: adminToken,
        tab: _tab,
        onTabChanged: (t) => setState(() => _tab = t),
        chatFocusNode: _chatFocus,
        onSendChat: _session.chat,
        onSay: session.isPlayer
            ? () => showSayDialog(context, ref, widget.tableId)
            : null,
        settings: (part) => TableSettingsTab(
          part: part,
          tableId: widget.tableId,
          isPlayer: session.isPlayer,
          onTakeSeat: _clearAndGoToJoin,
          onOtherTable: _otherTable,
          onLeave: session.isPlayer ? _leave : _clearAndGoToJoin,
          onShortcuts: () => showShortcutsOverlay(context),
          onRules: _showRules,
        ),
      ),
    );
    _panelWidget = panel;

    final uiScale = ref.watch(uiScaleProvider);
    final canDraw =
        session.isPlayer && (snap?.table.settings.allowDrawing ?? false);
    final table = Column(
      children: [
        if (banner != null)
          ConnectionBanner(
            text: banner,
            destructive: bannerDestructive,
            trailing: bannerAction,
          ),
        // The phase strip: your turn (highlighted), someone else's turn,
        // showdown, the countdown to the next deal, or the table state.
        // Always one line of the same height, so the table never jumps.
        if (snap != null)
          _PhaseStrip(
            key: const Key('turn-banner'),
            info: _phaseStripFor(snap, session, myTurn, l10n),
          ),
        Expanded(
          child: PadSectionScope(
            section: PadSection.table,
            child: TableView(
              session: session,
              onTakeSeat: _changeSeat,
              speaking: voice.speaking,
              onSayTap: session.isPlayer
                  ? () => showSayDialog(context, ref, widget.tableId)
                  : null,
              videoViews: voice.videoViews,
              voiceFailed: voice.failed,
              onSelfTap: session.isPlayer
                  ? () => showSelfMenu(context, ref, widget.tableId)
                  : null,
              onDraw: canDraw ? _session.draw : null,
              onErase: canDraw ? _session.eraseDrawings : null,
              onPlayerTap: (p) => showPlayerMenu(
                context,
                tableId: widget.tableId,
                player: p,
                admin: (snap?.you.isAdmin ?? false) && adminToken != null
                    ? AdminPlayerActions(
                        ref: ref,
                        context: context,
                        tableId: widget.tableId,
                        token: adminToken,
                      )
                    : null,
              ),
            ),
          ),
        ),
        // The accessibility scale enlarges the action bar's text and
        // buttons; cards and seats scale inside the table view.
        PadSectionScope(
          section: PadSection.actions,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(uiScale)),
            child: ActionBar(
              key: _actionBar,
              snapshot: snap,
              callbacks: callbacks,
              isPlayer: session.isPlayer,
              myStatus: myPlayer?.status,
              heldShortcut: _holdAction,
              chipDisplay: chipDisplay,
              handLine:
                  ref.watch(handLineProvider) == HandLinePlacement.bottom &&
                      session.isPlayer
                  ? snap?.you.handDescription
                  : null,
              shown: session.mySeat != null
                  ? session.shown[session.mySeat!] ?? const []
                  : const [],
              textFieldFocusChanged: (f) => _amountFocused = f,
            ),
          ),
        ),
        const PadHintBar(),
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
    final panelIcon = Stack(
      clipBehavior: Clip.none,
      children: [
        // On phones the panel is a sheet, so the icon says "menu".
        Icon(wide ? LucideIcons.panelRight : LucideIcons.menu),
        if (unread > 0 && !(wide && _panelOpen))
          Positioned(
            right: -6,
            top: -6,
            child: PrimaryBadge(child: Text(unread > 99 ? '99+' : '$unread')),
          ),
      ],
    );
    void togglePanel() {
      if (wide) {
        setState(() => _panelOpen = !_panelOpen);
      } else {
        _openSheet(panel);
      }
    }

    // Desktops get the word "Menu" next to the icon: an icon alone did not
    // tell players where chat, log and settings live.
    final panelButton = Tooltip(
      tooltip: TooltipContainer(child: Text(l10n.panelToggle)).call,
      child: compact
          ? GhostButton(
              key: const Key('panel-toggle'),
              density: ButtonDensity.icon,
              onPressed: togglePanel,
              child: panelIcon,
            )
          : GhostButton(
              key: const Key('panel-toggle'),
              onPressed: togglePanel,
              leading: panelIcon,
              child: Text(l10n.panelMenu),
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
    final speakingNow =
        voice.enabled &&
        !voice.muted &&
        voice.speaking.contains(VoiceEngine.self);
    final micColor = !voice.enabled
        ? theme.colorScheme.mutedForeground
        : voice.muted
        ? theme.colorScheme.destructive
        : const Color(0xFF43A047);
    // Microphone and camera: one press starts or stops each. The microphone
    // button joins the voice chat on the first press and mutes/unmutes after
    // that; the camera button joins the voice chat as well when needed.
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
            child: GhostButton(
              key: const Key('mic-button'),
              density: ButtonDensity.icon,
              onPressed: () => !voice.enabled
                  ? _voiceController.enable()
                  : _voiceController.toggleMute(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: speakingNow
                      ? const Color(0xFF43A047).withValues(alpha: 0.25)
                      : const Color(0x00000000),
                ),
                child: Icon(
                  !voice.enabled || voice.muted
                      ? LucideIcons.micOff
                      : speakingNow
                      ? LucideIcons.audioLines
                      : LucideIcons.mic,
                  color: micColor,
                ),
              ),
            ),
          )
        : null;
    final cameraButton = session.isPlayer
        ? Tooltip(
            tooltip: TooltipContainer(
              child: Text(voice.camera ? l10n.cameraOn : l10n.cameraOff),
            ).call,
            child: GhostButton(
              key: const Key('camera-button'),
              density: ButtonDensity.icon,
              onPressed: () => voice.enabled
                  ? _voiceController.toggleCamera()
                  : _voiceController.enable(camera: true),
              child: Icon(
                voice.camera ? LucideIcons.video : LucideIcons.videoOff,
                color: voice.camera
                    ? const Color(0xFF43A047)
                    : theme.colorScheme.mutedForeground,
              ),
            ),
          )
        : null;
    // The pencil: one button toggles drawing; while it is on, the eraser
    // and a clear menu sit next to it.
    final tool = ref.watch(drawToolProvider);
    final pencilButtons = <Widget>[
      if (canDraw) ...[
        Tooltip(
          tooltip: TooltipContainer(child: Text(l10n.drawPencil)).call,
          child: GhostButton(
            key: const Key('draw-pen'),
            density: ButtonDensity.icon,
            onPressed: () =>
                ref.read(drawToolProvider.notifier).toggle(DrawTool.pen),
            child: Icon(
              LucideIcons.pencil,
              color: tool == DrawTool.pen
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
          ),
        ),
        if (tool != DrawTool.none) ...[
          Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.drawEraser)).call,
            child: GhostButton(
              key: const Key('draw-eraser'),
              density: ButtonDensity.icon,
              onPressed: () =>
                  ref.read(drawToolProvider.notifier).toggle(DrawTool.eraser),
              child: Icon(
                LucideIcons.eraser,
                color: tool == DrawTool.eraser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.mutedForeground,
              ),
            ),
          ),
          Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.drawClearMine)).call,
            child: GhostButton(
              key: const Key('draw-clear-mine'),
              density: ButtonDensity.icon,
              onPressed: () => _session.clearDrawings(),
              child: Icon(
                LucideIcons.trash2,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
          Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.drawClearAll)).call,
            child: GhostButton(
              key: const Key('draw-clear-all'),
              density: ButtonDensity.icon,
              onPressed: () => _session.clearDrawings(all: true),
              child: Icon(
                LucideIcons.paintbrush,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    ];
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
          // Only once the server has said who we are: until the welcome
          // lands there is no role to show, and calling an unidentified
          // viewer a spectator is how a connecting player reads as one.
          if (session.identity != null && !session.isPlayer) ...[
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
                  '${snap.table.settings.tournament ? '${l10n.tournamentBadge} · ' : ''}${l10n.blindsShort(formatChips(snap.table.settings.smallBlind, locale), formatChips(snap.table.settings.bigBlind, locale))} · ${l10n.handNumber(snap.table.handNumber)}',
                ),
                if ((snap.table.nextBlindsUpTs ?? 0) > 0) ...[
                  const Text(' · '),
                  _BlindsCountdown(target: snap.table.nextBlindsUpTs!),
                ],
              ],
            ),
      trailing: [
        inviteButton,
        const Gap(4),
        ?micButton,
        ?cameraButton,
        ...pencilButtons,
        // Phones: the replay lives in the Log tab; the bar keeps the room
        // for the table name.
        if (!compact)
          Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.replayOpen)).call,
            child: GhostButton(
              key: const Key('replay-button'),
              density: ButtonDensity.icon,
              onPressed: snap == null ? null : _replay,
              child: Icon(
                LucideIcons.history,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        panelButton,
      ],
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

    if (session.showingResult && snap?.lastRound != null) {
      body = _RoundResultOverlay(
        result: snap!.lastRound!,
        newRound: snap.table.state != 'ended',
        // The host is offered the new round right where the standings are.
        onNewRound: snap.table.state == 'ended' && adminToken != null
            ? _newRound
            : null,
        // Closing the standings keeps the seat and the session: whoever is
        // here now plays the next round without joining again.
        onDismiss: ref
            .read(tableSessionProvider(widget.tableId).notifier)
            .dismissResult,
      );
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
      child: Scaffold(
        headers: [
          PadSectionScope(section: PadSection.table, child: header),
          const Divider(),
        ],
        child: body,
      ),
    );
  }

  void _openSheet(Widget panel) {
    openSheetOverlay<void>(
      context: context,
      position: OverlayPosition.bottom,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: Padding(padding: const EdgeInsets.all(12), child: panel),
            ),
            // The sheet covers the strip under the action bar.
            const PadHintBar(),
          ],
        ),
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

/// The standing of a finished round. It is the whole screen while the table
/// is ended; once the host opens a new round it stays exactly where it is —
/// same standings, same scroll position — and only the heading and the
/// button change, so nobody has the result pulled away mid-read. It goes
/// when the player says so (or when a hand is dealt to them, handled in
/// TableSessionNotifier).
class _RoundResultOverlay extends StatelessWidget {
  const _RoundResultOverlay({
    required this.result,
    required this.newRound,
    required this.onDismiss,
    this.onNewRound,
  });

  final RoundResult result;

  /// A new round is already running on this table.
  final bool newRound;

  /// Host only, while the table is ended: open a new round here.
  final VoidCallback? onNewRound;

  /// Closes the card and goes back to the table. It never touches the seat
  /// or the session — the player is in the next round either way.
  final VoidCallback onDismiss;

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
                Text(newRound ? l10n.newRoundTitle : l10n.tableEndedTitle).h3(),
                const Gap(4),
                Text(newRound ? l10n.newRoundBody : l10n.finalStandings)
                    .muted(),
                const Gap(12),
                if (newRound) ...[
                  Text(l10n.lastRoundTitle).semiBold().small(),
                  const Gap(4),
                ],
                for (final (i, e) in result.standings.indexed)
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
                if (newRound)
                  PrimaryButton(
                    key: const Key('result-back-to-table'),
                    onPressed: onDismiss,
                    child: Text(l10n.backToTable),
                  )
                else if (onNewRound != null) ...[
                  PrimaryButton(
                    key: const Key('result-new-round'),
                    leading: const Icon(LucideIcons.rotateCw),
                    onPressed: onNewRound,
                    child: Text(l10n.adminNewRound),
                  ),
                  const Gap(8),
                  OutlineButton(
                    key: const Key('result-close'),
                    onPressed: onDismiss,
                    child: Text(l10n.close),
                  ),
                ] else
                  PrimaryButton(
                    key: const Key('result-close'),
                    onPressed: onDismiss,
                    child: Text(l10n.close),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PhaseKind { myTurn, otherTurn, showdown, nextHand, idle }

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
  const _PhaseStrip({super.key, required this.info});
  final _PhaseInfo info;

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
      _PhaseKind.idle => info.name ?? '',
    };
    final bg = urgent
        ? theme.colorScheme.destructive
        : mine
        ? theme.colorScheme.primary
        : theme.colorScheme.muted;
    final fg = mine
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.mutedForeground;
    // The winners are not named here: the table shows them (pot on
    // display, chips flying, "+amount" at the stack, spotlight).
    final style = TextStyle(
      fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
      fontSize: 13,
      color: fg,
    );
    return Container(
      key: const Key('phase-strip'),
      width: double.infinity,
      height: phaseStripHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (info.kind != _PhaseKind.idle) ...[
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
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Height of the strip above the table; constant so the felt never moves.
const double phaseStripHeight = 30;

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
