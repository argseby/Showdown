import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/formatting.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/kbd_hint.dart';
import '../../../shared/shown_cards_icon.dart';
import '../action_model.dart';
import '../shortcuts.dart';

/// Callbacks the action bar needs from the session.
class ActionCallbacks {
  const ActionCallbacks({
    required this.act,
    required this.rebuy,
    required this.sitOut,
    required this.sitIn,
    required this.showCards,
    this.preAction,
    this.rabbitHunt,
    this.straddle,
    this.runTwice,
  });

  /// Arms or disarms the straddle (table setting allow_straddle).
  final ValueChanged<bool>? straddle;

  /// Answers the run-it-twice vote.
  final ValueChanged<bool>? runTwice;

  final void Function(String kind, {int? amount}) act;
  final VoidCallback rebuy;
  final VoidCallback sitOut;
  final VoidCallback sitIn;

  /// Shows the hole cards: "both", "first" or "second".
  final void Function(String which) showCards;
  final void Function(String kind)? preAction;
  final VoidCallback? rabbitHunt;
}

/// The player's controls. The bottom row is always the three colour-coded
/// action buttons, Fold (red), Check (green) or Call (blue) and Bet/Raise
/// (yellow), as equal-width buttons that are disabled off turn; Raise
/// unfolds the presets and the amount right above them. The pre-actions,
/// straddle, rebuy and sit out share the top row; the result controls
/// (run it twice, show cards, rabbit hunt) take a row in between while the
/// hand is over for the viewer.
/// Keyboard shortcuts are dispatched by the page through [ActionBarState].
class ActionBar extends StatefulWidget {
  const ActionBar({
    super.key,
    required this.snapshot,
    required this.callbacks,
    required this.isPlayer,
    required this.myStatus,
    required this.textFieldFocusChanged,
    this.chipDisplay = ChipDisplay.coins,
    this.shown = const [],
    this.handLine,
  });

  final Snapshot? snapshot;
  final ActionCallbacks callbacks;
  final bool isPlayer;
  final String? myStatus;

  /// Coins or big blinds for every amount, including the raise input.
  final ChipDisplay chipDisplay;

  /// "Your hand: …" shown at the bottom when the preference says so.
  final String? handLine;

  /// How long the action buttons stay disabled after the turn arrives, so
  /// a click aimed at something that was under the pointer a moment ago
  /// cannot fold or call by accident.
  static const armDelay = Duration(milliseconds: 400);

  /// Which of the viewer's cards are already shown this hand.
  final List<bool> shown;

  /// Called when the amount input gains/loses focus (shortcut suppression).
  final ValueChanged<bool> textFieldFocusChanged;

  @override
  State<ActionBar> createState() => ActionBarState();
}

class ActionBarState extends State<ActionBar> {
  bool _raiseOpen = false;
  int _amount = 0;
  String? _notice;
  var _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  /// Every raise panel gets a controller of its own. The text field keeps
  /// listening to the controller it was given after it is disposed, so a
  /// field of an earlier panel would keep reporting our programmatic
  /// changes as input, through a closure holding that turn's raise range,
  /// and clamp the new amount to it. The old controller (and with it the
  /// stale listener) goes once the frame that drops the old field is done.
  void _freshController() {
    final old = _amountController;
    _amountController = TextEditingController(text: old.text);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  ActionBarModel? get _model =>
      widget.snapshot == null ? null : ActionBarModel.from(widget.snapshot!);

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(
      () => widget.textFieldFocusChanged(_amountFocus.hasFocus),
    );
  }

  /// When the turn arrived; the action buttons ignore presses for
  /// [armDelay] after that, so a click aimed at something else that was
  /// under the pointer a moment ago cannot fold or call by accident.
  Timer? _armTimer;
  bool _armed = true;

  @override
  void didUpdateWidget(covariant ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final m = _model;
    final wasTurn =
        oldWidget.snapshot != null &&
        ActionBarModel.from(oldWidget.snapshot!) != null;
    if (m != null && !wasTurn) {
      _armed = false;
      _armTimer?.cancel();
      _armTimer = Timer(ActionBar.armDelay, () {
        if (mounted) setState(() => _armed = true);
      });
    } else if (m == null) {
      _armTimer?.cancel();
      _armed = true;
    }
    // The chosen amount belongs to the turn it was picked in: once the turn
    // is over, or the street or the hand has moved on, the raise control
    // starts from the minimum again instead of, say, last street's all-in.
    final oldSnap = oldWidget.snapshot;
    final newSnap = widget.snapshot;
    if (m == null ||
        oldSnap?.hand?.street != newSnap?.hand?.street ||
        oldSnap?.table.handNumber != newSnap?.table.handNumber) {
      _amount = 0;
    }
    if (m == null || !m.canRaise) {
      if (_raiseOpen) setState(() => _raiseOpen = false);
      return;
    }
    if (_raiseOpen) {
      final clamped = m.clamp(_amount);
      if (clamped != _amount) _setAmount(clamped, notice: false);
    }
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Sends an action; the amount picked for it does not outlive the turn.
  void _act(String kind, {int? amount}) {
    _amount = 0;
    widget.callbacks.act(kind, amount: amount);
  }

  // ---- keyboard entry points -------------------------------------------------------------

  /// Folds; when a check is free the player is asked first (a fold would
  /// throw the hand away for nothing).
  void fold() {
    final m = _model;
    if (m == null || !m.canFold) return;
    if (m.canCheck) {
      _confirmFold();
      return;
    }
    _act('fold');
  }

  Future<void> _confirmFold() async {
    final l10n = context.l10n;
    final choice = await showOverlay<String>(
      context,
      const DialogConfiguration(),
      builder: (context) => AlertDialog(
        title: Text(l10n.foldCheckTitle),
        content: Text(l10n.foldCheckBody),
        actions: [
          PrimaryButton(
            key: const Key('fold-check-instead'),
            onPressed: () => closeOverlay<String>(context, 'check'),
            child: Text(l10n.foldCheckInstead),
          ),
          DestructiveButton(
            key: const Key('fold-anyway'),
            onPressed: () => closeOverlay<String>(context, 'fold'),
            child: Text(l10n.foldAnyway),
          ),
        ],
      ),
    ).future;
    if (!mounted || choice == null) return;
    final m = _model;
    if (m == null) return;
    if (choice == 'check' && m.canCheck) {
      _act('check');
    } else if (choice == 'fold' && m.canFold) {
      _act('fold');
    }
  }

  void checkOrCall() {
    final m = _model;
    if (m == null) return;
    if (m.canCheck) {
      _act('check');
    } else if (m.canCall) {
      _act('call');
    }
  }

  /// Opens the raise panel and puts the caret into the amount field, so the
  /// number can be typed; Esc leaves the field again.
  void focusAmount() {
    final m = _model;
    if (m == null || !m.canRaise) return;
    if (!_raiseOpen) openRaise(focusInput: false);
    _amountFocus.requestFocus();
    _amountController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountController.text.length,
    );
  }

  /// Opens the raise panel. The amount field is not focused by default so
  /// that the letter shortcuts (A, 1-4) keep working; N focuses it.
  void openRaise({bool focusInput = false}) {
    final m = _model;
    if (m == null || !m.canRaise) return;
    if (!_raiseOpen) _freshController();
    setState(() {
      _raiseOpen = true;
      _notice = null;
      _setAmount(_amount == 0 ? m.raise!.min : m.clamp(_amount), notice: false);
    });
    if (focusInput) {
      _amountFocus.requestFocus();
      _amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountController.text.length,
      );
    }
  }

  void selectAllIn() {
    final m = _model;
    if (m == null || !m.canAllIn) return;
    if (!m.canRaise) {
      // A short call: all-in is immediate since Enter would have nothing to confirm.
      _act('all_in');
      return;
    }
    openRaise(focusInput: false);
    _setAmount(m.raise!.max, notice: false);
  }

  void preset(int index) {
    final m = _model;
    if (m == null || !m.canRaise) return;
    if (!_raiseOpen) openRaise(focusInput: false);
    const fractions = [0.0, 0.5, 0.75, 1.0];
    _setAmount(m.preset(fractions[index.clamp(0, 3)]), notice: false);
  }

  void adjust(int blinds) {
    final m = _model;
    if (m == null || !m.canRaise) return;
    if (!_raiseOpen) openRaise(focusInput: false);
    _setAmount(m.clamp(_amount + blinds * m.bigBlind), notice: false);
  }

  /// Confirms the raise control; returns false when nothing was pending.
  bool confirm() {
    final m = _model;
    if (!_raiseOpen || m == null || !m.canRaise) return false;
    final amount = m.clamp(_parseInput() ?? _amount);
    _act(m.isOpeningBet ? 'bet' : 'raise', amount: amount);
    setState(() => _raiseOpen = false);
    return true;
  }

  /// Closes the raise control; returns false when it was closed already.
  bool cancel() {
    if (!_raiseOpen) return false;
    setState(() {
      _raiseOpen = false;
      _notice = null;
    });
    _amountFocus.unfocus();
    return true;
  }

  bool get raiseOpen => _raiseOpen;

  bool get _bbMode =>
      widget.chipDisplay == ChipDisplay.bigBlinds &&
      (_model?.bigBlind ?? 0) > 0;

  /// Formats an amount in the current display mode.
  String _fmt(int amount) => formatAmount(
    amount,
    mode: widget.chipDisplay,
    bigBlind: _model?.bigBlind ?? 0,
    locale: _locale,
  );

  /// Parses the amount field: chips, or big blinds in BB mode.
  int? _parseInput() {
    final text = _amountController.text;
    if (_bbMode) return parseBigBlinds(text, _model!.bigBlind);
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  /// Text for the amount field in the current mode.
  String _inputText(int amount) => _bbMode
      ? formatBigBlinds(amount, _model!.bigBlind, 'en')
      : amount.toString();

  void _setAmount(int amount, {required bool notice}) {
    final m = _model;
    final clamped = m?.clamp(amount) ?? amount;
    setState(() {
      _amount = clamped;
      _notice = notice && clamped != amount
          ? context.l10n.amountClamped(_fmt(clamped))
          : null;
      final text = _inputText(clamped);
      if (_amountController.text != text) {
        _amountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  String get _locale => Localizations.localeOf(context).toString();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final m = _model;
    final snap = widget.snapshot;
    final you = snap?.you;
    final sittingOut = widget.myStatus == 'sitting_out';
    final myTurn = m != null;

    Widget content;
    if (!widget.isPlayer) {
      content = Center(
        child: Text(
          you?.role == 'admin' ? l10n.roleAdmin : l10n.roleSpectator,
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    } else if (sittingOut) {
      // Away: the hand is folded on the server; only "I'm back".
      content = Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.sittingOutNotice).muted().small(),
          PrimaryButton(
            key: const Key('sit-in'),
            size: ButtonSize.small,
            onPressed: widget.callbacks.sitIn,
            child: Text(l10n.sitIn),
          ),
        ],
      );
    } else {
      // The three action buttons are always the bottom row (disabled off
      // turn and between hands) so that nothing ever changes meaning under
      // the pointer. The pre-actions, straddle, rebuy and sit out share the
      // top row in a different look; the result controls, while the hand is
      // over for the viewer, take a row in between.
      // Once the viewer has folded, the pre-actions are moot until the next
      // hand, so the toggles are disabled along with the action buttons.
      final folded = !myTurn && _hasFolded(snap!, you!);
      // Once the hand is over for the viewer the show-cards and rabbit
      // hunt buttons take the bottom row at full size; otherwise the three
      // action buttons are always there.
      final result = _resultButtons(context, you!);
      final actions = result ?? _turnRows(context, m);
      final rows = <Widget>[
        ?_topRow(context, you, togglesEnabled: !myTurn && !folded),
        ?_resultRow(context, you),
        if (folded && result == null)
          _foldedNotice(context, actions)
        else
          actions,
      ];
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Gap(6),
            row,
          ],
        ],
      );
    }

    final handLine = widget.handLine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (handLine != null && handLine.isNotEmpty) ...[
            const Gap(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 12,
                  color: theme.colorScheme.mutedForeground,
                ),
                const Gap(6),
                Text(
                  l10n.yourHand(handLine),
                  key: const Key('your-hand-bottom'),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The viewer folded the running hand.
  bool _hasFolded(Snapshot snap, You you) {
    if (snap.hand == null) return false;
    for (final sv in snap.seats) {
      if (sv.seat == you.seat) return sv.player?.folded ?? false;
    }
    return false;
  }

  /// Takes the place of the action buttons while the viewer is out of the
  /// hand. The buttons stay in the tree, invisible and inert, so the bar
  /// keeps exactly their height and nothing jumps; a muted "You folded"
  /// strip fills their footprint and says why nothing can be pressed.
  Widget _foldedNotice(BuildContext context, Widget actions) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.mutedForeground;
    return Stack(
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: actions,
        ),
        Positioned.fill(
          child: Container(
            key: const Key('folded-notice'),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.x, size: 18, color: color),
                const Gap(6),
                Text(
                  context.l10n.youFolded,
                  style: TextStyle(color: color),
                ).semiBold(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The top row, left aligned and clearly apart from the action buttons:
  /// check/fold and call any as small check-box style toggles (disabled on
  /// turn and once the viewer has folded), the straddle, rebuy and sit out.
  /// Null when there is nothing to show.
  Widget? _topRow(
    BuildContext context,
    You you, {
    required bool togglesEnabled,
  }) {
    final l10n = context.l10n;
    final enabled = togglesEnabled;
    Widget toggle(String kind, String label, Key key) {
      final on = you.preAction == kind;
      void cb() => widget.callbacks.preAction!(on ? 'none' : kind);
      final icon = Icon(
        on ? LucideIcons.squareCheck : LucideIcons.square,
        size: 14,
      );
      return on
          ? PrimaryButton(
              key: key,
              size: ButtonSize.small,
              onPressed: enabled ? cb : null,
              leading: icon,
              child: Text(label),
            )
          : OutlineButton(
              key: key,
              size: ButtonSize.small,
              onPressed: enabled ? cb : null,
              leading: icon,
              child: Text(label),
            );
    }

    final snap = widget.snapshot!;
    final items = <Widget>[
      // Pre-actions may be armed at any time (also while waiting for the
      // next hand), so the toggles are always there for a seated player.
      if (widget.callbacks.preAction != null) ...[
        toggle('check_fold', l10n.preCheckFold, const Key('pre-check-fold')),
        toggle('call_any', l10n.preCallAny, const Key('pre-call-any')),
      ],
      // The straddle is armed for the next hand: same row, same look.
      if (snap.table.settings.allowStraddle &&
          widget.callbacks.straddle != null &&
          widget.myStatus == 'active')
        _straddleToggle(context, you),
      if (you.canRebuy) _rebuyButton(context),
      if (widget.myStatus == 'active') _sitOutButton(context),
    ];
    if (items.isEmpty) return null;
    // One line that scrolls sideways on narrow screens, so the toggles
    // never wrap onto a second row.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const Gap(6),
            item,
          ],
        ],
      ),
    );
  }

  Widget _straddleToggle(BuildContext context, You you) {
    final l10n = context.l10n;
    final on = you.straddle ?? false;
    return Tooltip(
      tooltip: TooltipContainer(child: Text(l10n.straddleHint)).call,
      child: (on ? PrimaryButton.new : OutlineButton.new)(
        key: const Key('straddle-toggle'),
        size: ButtonSize.small,
        onPressed: () => widget.callbacks.straddle!(!on),
        leading: Icon(
          on ? LucideIcons.squareCheck : LucideIcons.square,
          size: 14,
        ),
        child: Text(l10n.straddleToggle),
      ),
    );
  }

  /// Rebuy for the table's starting stack; offered when the viewer is broke.
  Widget _rebuyButton(BuildContext context) => SecondaryButton(
    key: const Key('rebuy'),
    size: ButtonSize.small,
    onPressed: widget.callbacks.rebuy,
    leading: const Icon(LucideIcons.coins, size: 14),
    child: Text(
      context.l10n.rebuy(_fmt(widget.snapshot!.table.settings.startMoney)),
    ),
  );

  /// "Sit out" at the end of the top row, in the same look as rebuy.
  Widget _sitOutButton(BuildContext context) => SecondaryButton(
    key: const Key('sit-out'),
    size: ButtonSize.small,
    onPressed: widget.callbacks.sitOut,
    leading: const Icon(LucideIcons.armchair, size: 14),
    child: Text(context.l10n.sitOut),
  );

  /// The viewer's turn: presets and amount (when raising) above the three
  /// colour-coded action buttons.
  /// The action row: live on the viewer's turn (after [armDelay]), shown
  /// disabled otherwise so the layout never jumps.
  Widget _turnRows(BuildContext context, ActionBarModel? m) {
    final l10n = context.l10n;
    final armed = m != null && _armed;
    if (m == null) {
      // Off turn the button still says what the action would be: a bet
      // while nobody has put chips in on this street, a raise after that.
      final opening = widget.snapshot?.hand?.currentBet == 0;
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              key: const Key('action-fold'),
              label: l10n.fold,
              hint: shortcutLabel(ShortcutAction.fold),
              enabled: false,
              color: ActionColors.fold,
              onPressed: () {},
            ),
          ),
          const Gap(6),
          Expanded(
            child: _ActionButton(
              key: const Key('action-check-call'),
              label: l10n.check,
              hint: shortcutLabel(ShortcutAction.checkCall),
              enabled: false,
              color: ActionColors.check,
              onPressed: () {},
            ),
          ),
          const Gap(6),
          Expanded(
            child: _ActionButton(
              key: const Key('action-raise'),
              label: opening ? l10n.bet : l10n.raise,
              hint: shortcutLabel(ShortcutAction.openRaise),
              enabled: false,
              color: ActionColors.raise,
              onPressed: () {},
            ),
          ),
        ],
      );
    }
    final raiseLabel = m.isOpeningBet ? l10n.bet : l10n.raise;
    final rows = <Widget>[];
    if (_raiseOpen && m.canRaise) {
      rows.add(
        _RaisePanel(
          model: m,
          amount: _amount,
          controller: _amountController,
          focusNode: _amountFocus,
          notice: _notice,
          fmt: _fmt,
          bbMode: _bbMode,
          onAmount: (v) => _setAmount(v, notice: true),
          onInput: (text) {
            // The field reports our own changes (presets, clamping) too;
            // only typed text is news, and it is judged by the range of
            // the turn it arrives in.
            final m = _model;
            if (m == null || !m.canRaise || text == _inputText(_amount)) {
              return;
            }
            final v = _bbMode
                ? parseBigBlinds(text, m.bigBlind)
                : int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
            if (v != null) {
              final clamped = m.clamp(v);
              setState(() {
                _amount = clamped;
                _notice = clamped != v
                    ? l10n.amountRange(_fmt(m.raise!.min), _fmt(m.raise!.max))
                    : null;
              });
            }
          },
          onPreset: preset,
          onConfirm: confirm,
        ),
      );
      rows.add(const Gap(6));
    }
    final callLabel = m.canCall ? l10n.call(_fmt(m.callAmount)) : l10n.check;
    rows.add(
      Row(
        children: [
          Expanded(
            child: _ActionButton(
              key: const Key('action-fold'),
              label: l10n.fold,
              hint: shortcutLabel(ShortcutAction.fold),
              enabled: m.canFold && armed,
              color: ActionColors.fold,
              onPressed: fold,
            ),
          ),
          const Gap(6),
          Expanded(
            child: _ActionButton(
              key: const Key('action-check-call'),
              label: callLabel,
              hint: shortcutLabel(ShortcutAction.checkCall),
              enabled: (m.canCheck || m.canCall) && armed,
              color: m.canCall ? ActionColors.call : ActionColors.check,
              onPressed: checkOrCall,
            ),
          ),
          const Gap(6),
          Expanded(
            flex: _raiseOpen ? 2 : 1,
            child: _ActionButton(
              key: const Key('action-raise'),
              label: !_raiseOpen
                  ? raiseLabel
                  : m.isOpeningBet
                  ? l10n.betAmount(_fmt(_amount))
                  : l10n.raiseTo(_fmt(_amount)),
              hint: shortcutLabel(
                _raiseOpen ? ShortcutAction.confirm : ShortcutAction.openRaise,
              ),
              enabled: m.canRaise && armed,
              color: ActionColors.raise,
              onPressed: () => _raiseOpen ? confirm() : openRaise(),
            ),
          ),
          if (_raiseOpen) ...[
            const Gap(6),
            GhostButton(
              key: const Key('raise-cancel'),
              size: actionButtonSize,
              density: ButtonDensity.icon,
              onPressed: cancel,
              child: const Icon(LucideIcons.x, size: 20),
            ),
          ],
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  /// The run-it-twice vote (or its outcome) while it is pending; null
  /// otherwise.
  Widget? _resultRow(BuildContext context, You you) {
    final l10n = context.l10n;
    final snap = widget.snapshot!;
    final items = <Widget>[];
    if ((you.canRunTwice ?? false) && widget.callbacks.runTwice != null) {
      items.add(Text(l10n.runTwiceQuestion).semiBold().small());
      items.add(
        PrimaryButton(
          key: const Key('run-twice-yes'),
          size: ButtonSize.small,
          onPressed: () => widget.callbacks.runTwice!(true),
          child: Text(l10n.runTwiceYes),
        ),
      );
      items.add(
        OutlineButton(
          key: const Key('run-twice-no'),
          size: ButtonSize.small,
          onPressed: () => widget.callbacks.runTwice!(false),
          child: Text(l10n.runTwiceNo),
        ),
      );
    } else if (you.runTwiceVote != null &&
        (snap.hand?.runTwiceEndsTs ?? 0) > 0) {
      items.add(
        Text(
          you.runTwiceVote! ? l10n.runTwiceWaiting : l10n.runTwiceDeclined,
          key: const Key('run-twice-status'),
        ).muted().small(),
      );
    }
    if (items.isEmpty) return null;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  /// Show first / second / both cards and rabbit hunt as equal-width,
  /// full-size buttons in place of the action buttons once the hand is
  /// over for the viewer; null while none is on offer.
  Widget? _resultButtons(BuildContext context, You you) {
    final l10n = context.l10n;
    final items = <Widget>[];
    final compact = isCompactActionBar(context);
    Widget label(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: compact ? const TextStyle(fontSize: compactActionLabelSize) : null,
    );
    if (you.canShowCards) {
      final first = widget.shown.isNotEmpty && widget.shown[0];
      final second = widget.shown.length > 1 && widget.shown[1];
      // On narrow screens the three buttons say it with the cards alone:
      // the white card (with its little ace) is the one that gets shown.
      Widget cards(String text, {required bool a, required bool b}) => compact
          ? Semantics(
              label: text,
              button: true,
              child: ShownCardsIcon(first: a, second: b),
            )
          : label(text);
      items.add(
        OutlineButton(
          key: const Key('show-first'),
          size: actionButtonSize,
          alignment: Alignment.center,
          onPressed: first ? null : () => widget.callbacks.showCards('first'),
          child: cards(l10n.showFirstCard, a: true, b: false),
        ),
      );
      items.add(
        OutlineButton(
          key: const Key('show-second'),
          size: actionButtonSize,
          alignment: Alignment.center,
          onPressed: second ? null : () => widget.callbacks.showCards('second'),
          child: cards(l10n.showSecondCard, a: false, b: true),
        ),
      );
      items.add(
        SecondaryButton(
          key: const Key('show-both'),
          size: actionButtonSize,
          alignment: Alignment.center,
          onPressed: () => widget.callbacks.showCards('both'),
          leading: compact ? null : const Icon(LucideIcons.eye, size: 18),
          child: cards(l10n.showCards, a: true, b: true),
        ),
      );
    }
    if (you.canRabbitHunt && widget.callbacks.rabbitHunt != null) {
      items.add(
        SecondaryButton(
          key: const Key('rabbit-hunt'),
          size: actionButtonSize,
          alignment: Alignment.center,
          onPressed: widget.callbacks.rabbitHunt,
          leading: const Icon(LucideIcons.rabbit, size: 18),
          child: label(l10n.rabbitHunt),
        ),
      );
    }
    if (items.isEmpty) return null;
    return Row(
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) const Gap(6),
          Expanded(child: item),
        ],
      ],
    );
  }
}

/// The size of the bottom row (action buttons, show-cards buttons, the
/// folded notice): one and a half times the small buttons above it.
const ButtonSize actionButtonSize = ButtonSize(1.125);

/// Below this width the bottom row is a phone: smaller labels, and no
/// keyboard hints since there is no keyboard.
const double compactActionBarWidth = 600;

/// Whether the bar is on a phone-sized screen.
bool isCompactActionBar(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactActionBarWidth;

/// The label size of the bottom row on a phone.
const double compactActionLabelSize = 12;

/// The colour code of the action buttons.
class ActionColors {
  const ActionColors._();
  static const fold = Color(0xFFD64545);
  static const check = Color(0xFF3AA655);
  static const call = Color(0xFF3B82F6);
  static const raise = Color(0xFFE6B422);
}

/// A compact, colour-coded action button that fills its slot.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final String hint;
  final bool enabled;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fg = color == ActionColors.raise
        ? const Color(0xFF2B2200)
        : const Color(0xFFFFFFFF);
    final compact = isCompactActionBar(context);
    return Button(
      style: const ButtonStyle.primary(size: actionButtonSize).copyWith(
        decoration: (context, states, value) {
          final base = value as BoxDecoration;
          var c = color;
          if (states.contains(WidgetState.disabled)) {
            c = color.withValues(alpha: 0.35);
          } else if (states.contains(WidgetState.pressed)) {
            c = Color.lerp(color, const Color(0xFF000000), 0.25)!;
          } else if (states.contains(WidgetState.hovered)) {
            c = Color.lerp(color, const Color(0xFFFFFFFF), 0.12)!;
          }
          return base.copyWith(color: c);
        },
        textStyle: (context, states, value) => value.copyWith(
          color: states.contains(WidgetState.disabled)
              ? fg.withValues(alpha: 0.7)
              : fg,
          fontWeight: FontWeight.w600,
          fontSize: compact ? compactActionLabelSize : null,
        ),
      ),
      onPressed: enabled ? onPressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (!compact) ...[const Gap(6), KbdHint(hint)],
        ],
      ),
    );
  }
}

/// Presets as equal-width buttons plus the amount (slider, field, ± big
/// blind), laid out like the action row so that nothing is easy to mispress.
class _RaisePanel extends StatelessWidget {
  const _RaisePanel({
    required this.model,
    required this.amount,
    required this.controller,
    required this.focusNode,
    required this.notice,
    required this.fmt,
    required this.bbMode,
    required this.onAmount,
    required this.onInput,
    required this.onPreset,
    required this.onConfirm,
  });

  final ActionBarModel model;
  final int amount;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? notice;
  final String Function(int) fmt;
  final bool bbMode;
  final ValueChanged<int> onAmount;
  final ValueChanged<String> onInput;
  final ValueChanged<int> onPreset;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final r = model.raise!;
    final range = (r.max - r.min).toDouble();
    final sliderValue = range <= 0
        ? 0.0
        : ((amount - r.min) / range).clamp(0.0, 1.0);
    final presets = <(String, int?, String)>[
      (l10n.presetMin, 0, shortcutLabel(ShortcutAction.preset1)),
      (l10n.presetHalfPot, 1, shortcutLabel(ShortcutAction.preset2)),
      (l10n.presetThreeQuarterPot, 2, shortcutLabel(ShortcutAction.preset3)),
      (l10n.presetPot, 3, shortcutLabel(ShortcutAction.preset4)),
      (l10n.presetAllIn, null, shortcutLabel(ShortcutAction.selectAllIn)),
    ];
    final bb = model.bigBlind;
    return Container(
      key: const Key('raise-control'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final (i, (label, index, hint)) in presets.indexed) ...[
                if (i > 0) const Gap(6),
                Expanded(
                  child: OutlineButton(
                    key: index == null
                        ? const Key('action-all-in')
                        : Key('preset-$index'),
                    size: ButtonSize.small,
                    onPressed: () =>
                        index == null ? onAmount(r.max) : onPreset(index),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        ),
                        const Gap(4),
                        KbdHint(hint),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(6),
          Row(
            children: [
              OutlineButton(
                key: const Key('amount-down'),
                size: ButtonSize.small,
                density: ButtonDensity.icon,
                onPressed: bb > 0 ? () => onAmount(amount - bb) : null,
                child: const Icon(LucideIcons.minus, size: 14),
              ),
              const Gap(6),
              Expanded(
                child: Slider(
                  value: SliderValue.single(sliderValue),
                  onChanged: range <= 0
                      ? null
                      : (v) {
                          final raw = r.min + (v.value * range).round();
                          final stepped = bb > 0 ? (raw ~/ bb) * bb : raw;
                          onAmount(stepped < r.min ? r.min : stepped);
                        },
                ),
              ),
              const Gap(6),
              OutlineButton(
                key: const Key('amount-up'),
                size: ButtonSize.small,
                density: ButtonDensity.icon,
                onPressed: bb > 0 ? () => onAmount(amount + bb) : null,
                child: const Icon(LucideIcons.plus, size: 14),
              ),
              const Gap(8),
              SizedBox(
                width: 96,
                child: TextField(
                  key: const Key('raise-amount'),
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    if (bbMode)
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                    else
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: onInput,
                  onSubmitted: (_) => onConfirm(),
                ),
              ),
              if (bbMode) ...[const Gap(4), const Text('BB').muted().small()],
            ],
          ),
          const Gap(2),
          Text(
            notice ?? l10n.amountRange(fmt(r.min), fmt(r.max)),
            key: const Key('raise-notice'),
            style: TextStyle(
              fontSize: 11,
              color: notice != null
                  ? theme.colorScheme.destructive
                  : theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
