import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/formatting.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/kbd_hint.dart';
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
  });

  final void Function(String kind, {int? amount}) act;
  final VoidCallback rebuy;
  final VoidCallback sitOut;
  final VoidCallback sitIn;

  /// Shows the hole cards: "both", "first" or "second".
  final void Function(String which) showCards;
  final void Function(String kind)? preAction;
  final VoidCallback? rabbitHunt;
}

/// The player's controls. On the viewer's turn: Fold (red), Check (green) or
/// Call (blue) and Bet/Raise (yellow) as equal-width buttons; Raise unfolds
/// the presets and the amount right above the buttons. Off turn only the
/// pre-actions show, after the hand only show-cards / rabbit hunt / rebuy.
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
  });

  final Snapshot? snapshot;
  final ActionCallbacks callbacks;
  final bool isPlayer;
  final String? myStatus;

  /// Coins or big blinds for every amount, including the raise input.
  final ChipDisplay chipDisplay;

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
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  ActionBarModel? get _model =>
      widget.snapshot == null ? null : ActionBarModel.from(widget.snapshot!);

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(
      () => widget.textFieldFocusChanged(_amountFocus.hasFocus),
    );
  }

  @override
  void didUpdateWidget(covariant ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final m = _model;
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
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
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
    widget.callbacks.act('fold');
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
      widget.callbacks.act('check');
    } else if (choice == 'fold' && m.canFold) {
      widget.callbacks.act('fold');
    }
  }

  void checkOrCall() {
    final m = _model;
    if (m == null) return;
    if (m.canCheck) {
      widget.callbacks.act('check');
    } else if (m.canCall) {
      widget.callbacks.act('call');
    }
  }

  void openRaise({bool focusInput = true}) {
    final m = _model;
    if (m == null || !m.canRaise) return;
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
      widget.callbacks.act('all_in');
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
    widget.callbacks.act(m.isOpeningBet ? 'bet' : 'raise', amount: amount);
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

    final handLine = widget.isPlayer && (you?.handDescription ?? '').isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 12,
                  color: theme.colorScheme.mutedForeground,
                ),
                const Gap(6),
                Text(
                  l10n.yourHand(you!.handDescription),
                  key: const Key('your-hand'),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          )
        : null;

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
    } else if (myTurn) {
      content = _turnRows(context, m);
    } else {
      content = _offTurnRow(context, you!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?handLine, content],
      ),
    );
  }

  /// Small "sit out" control that rides along at the end of a row.
  Widget _sitOutButton(BuildContext context) => Tooltip(
    tooltip: TooltipContainer(child: Text(context.l10n.sitOut)).call,
    child: GhostButton(
      key: const Key('sit-out'),
      size: ButtonSize.small,
      density: ButtonDensity.icon,
      onPressed: widget.callbacks.sitOut,
      child: const Icon(LucideIcons.armchair, size: 16),
    ),
  );

  /// The viewer's turn: presets and amount (when raising) above the three
  /// colour-coded action buttons.
  Widget _turnRows(BuildContext context, ActionBarModel m) {
    final l10n = context.l10n;
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
              enabled: m.canFold,
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
              enabled: m.canCheck || m.canCall,
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
              enabled: m.canRaise,
              color: ActionColors.raise,
              onPressed: () => _raiseOpen ? confirm() : openRaise(),
            ),
          ),
          if (_raiseOpen) ...[
            const Gap(6),
            GhostButton(
              key: const Key('raise-cancel'),
              size: ButtonSize.small,
              density: ButtonDensity.icon,
              onPressed: cancel,
              child: const Icon(LucideIcons.x, size: 16),
            ),
          ],
          if (widget.myStatus == 'active') ...[
            const Gap(4),
            _sitOutButton(context),
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

  /// Not the viewer's turn: pre-actions during a hand, otherwise the
  /// result-phase controls (show cards, rabbit hunt, rebuy).
  Widget _offTurnRow(BuildContext context, You you) {
    final l10n = context.l10n;
    final snap = widget.snapshot!;
    final items = <Widget>[];
    // Pre-actions stay armed across hands, so they can be toggled whenever
    // it is not the viewer's turn, including between hands.
    if (widget.callbacks.preAction != null) {
      Widget toggle(String kind, String label, Key key) {
        final on = you.preAction == kind;
        void cb() => widget.callbacks.preAction!(on ? 'none' : kind);
        return on
            ? PrimaryButton(
                key: key,
                size: ButtonSize.small,
                onPressed: cb,
                child: Text(label),
              )
            : OutlineButton(
                key: key,
                size: ButtonSize.small,
                onPressed: cb,
                child: Text(label),
              );
      }

      items.add(
        toggle('check_fold', l10n.preCheckFold, const Key('pre-check-fold')),
      );
      items.add(toggle('call_any', l10n.preCallAny, const Key('pre-call-any')));
    }
    if (you.canRebuy) {
      items.add(
        SecondaryButton(
          size: ButtonSize.small,
          onPressed: widget.callbacks.rebuy,
          leading: const Icon(LucideIcons.coins, size: 14),
          child: Text(l10n.rebuy(_fmt(snap.table.settings.startMoney))),
        ),
      );
    }
    if (you.canShowCards) {
      final first = widget.shown.isNotEmpty && widget.shown[0];
      final second = widget.shown.length > 1 && widget.shown[1];
      items.add(
        OutlineButton(
          key: const Key('show-first'),
          size: ButtonSize.small,
          onPressed: first ? null : () => widget.callbacks.showCards('first'),
          child: Text(l10n.showFirstCard),
        ),
      );
      items.add(
        OutlineButton(
          key: const Key('show-second'),
          size: ButtonSize.small,
          onPressed: second ? null : () => widget.callbacks.showCards('second'),
          child: Text(l10n.showSecondCard),
        ),
      );
      items.add(
        SecondaryButton(
          key: const Key('show-both'),
          size: ButtonSize.small,
          onPressed: () => widget.callbacks.showCards('both'),
          leading: const Icon(LucideIcons.eye, size: 14),
          child: Text(l10n.showCards),
        ),
      );
    }
    if (you.canRabbitHunt && widget.callbacks.rabbitHunt != null) {
      items.add(
        SecondaryButton(
          key: const Key('rabbit-hunt'),
          size: ButtonSize.small,
          onPressed: widget.callbacks.rabbitHunt,
          leading: const Icon(LucideIcons.rabbit, size: 14),
          child: Text(l10n.rabbitHunt),
        ),
      );
    }
    if (widget.myStatus == 'active') items.add(_sitOutButton(context));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }
}

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
    return Button(
      style: const ButtonStyle.primary(size: ButtonSize.small).copyWith(
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
        ),
      ),
      onPressed: enabled ? onPressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const Gap(6),
          KbdHint(hint),
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
