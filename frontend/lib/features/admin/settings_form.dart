import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../shared/confirm_dialog.dart';
import 'settings_form_model.dart';

/// The §5.2 settings form. [state] is owned by the caller; every change is
/// reported through [onChanged]. [serverErrors] come from the API response.
///
/// With [onApply] the form settles each change by itself: a switch or a
/// choice the moment it is made, a typed value on the tick beside it, and
/// the cross puts it back. Without it the caller gathers the whole state
/// and sends it once, which is what making a table does.
class SettingsForm extends StatefulWidget {
  const SettingsForm({
    super.key,
    required this.state,
    required this.onChanged,
    required this.errors,
    this.onApply,
    this.serverErrors = const {},
    this.showName = false,
    this.showPasswordKeepHint = false,
    this.seated = 0,
    this.locked = const {},
  });

  final SettingsFormState state;
  final ValueChanged<SettingsFormState> onChanged;

  /// Applies one field; null while the form is being filled in as a whole.
  final void Function(SettingsFormState next, String field)? onApply;
  final Map<String, SettingsError> errors;
  final Map<String, String> serverErrors;
  final bool showName;
  final bool showPasswordKeepHint;
  final int seated;

  /// Fields a running tournament refuses to change (shown disabled).
  final Set<String> locked;

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  /// One controller per typed field. A TextField given only an initial
  /// value keeps its own text for ever, so the cross beside it would put
  /// the model back and leave the typing on screen.
  final _controllers = <String, TextEditingController>{};

  @override
  void didUpdateWidget(SettingsForm old) {
    super.didUpdateWidget(old);
    // The boxes follow the model when a value is settled or put back, but
    // only once the frame is done: touching a controller while the tree is
    // being laid out marks a widget dirty mid-build, which Flutter refuses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final e in _controllers.entries) {
        final value = e.key == 'password'
            ? widget.state.password
            : widget.state.numbers[e.key] ?? '';
        // While somebody types, the two already agree and nothing moves.
        if (value != e.value.text) e.value.text = value;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, String value) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: value));

  String? _errorText(AppLocalizations l10n, String field) {
    final server = widget.serverErrors[field];
    if (server != null) return server;
    switch (widget.errors[field]) {
      case null:
        return null;
      case SettingsError.integer:
        return l10n.valInteger;
      case SettingsError.maxPlayers:
        return l10n.valRange('2', '10');
      case SettingsError.maxPlayersRoyal:
        return l10n.valRoyalMaxPlayers;
      case SettingsError.startMoney:
        return l10n.valRange('1', '1,000,000,000,000');
      case SettingsError.smallBlind:
        return l10n.valMin('1');
      case SettingsError.bigBlind:
        return l10n.valBigBlind;
      case SettingsError.ante:
        return l10n.valMin('0');
      case SettingsError.turnTime:
        return l10n.valRange('5', '600');
      case SettingsError.disconnected:
        return l10n.valDisconnected;
      case SettingsError.sitOut:
        return l10n.valRange('1', '10');
      case SettingsError.handDelay:
        return l10n.valRange('2000', '15000');
      case SettingsError.blindsUpMinutes:
        return l10n.valRange('0', '600');
      case SettingsError.timeBank:
        return l10n.errTimeBank;
      case SettingsError.timeBankRefill:
        return l10n.errTimeBankRefill;
      case SettingsError.blindsUpPercent:
        return l10n.valRange('10', '400');
      case SettingsError.password:
        return l10n.valPassword;
      case SettingsError.name:
        return l10n.adminTableNameInvalid;
    }
  }

  String _applies(AppLocalizations l10n, String field) =>
      switch (settingsApplies[field]) {
        AppliesWhen.nextHand => l10n.adminAppliesNextHand,
        AppliesWhen.nextJoin => l10n.adminAppliesNextJoin,
        AppliesWhen.futureJoins => l10n.adminAppliesFuture,
        _ => l10n.adminAppliesImmediately,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Widget field(String key, String label, Widget input) {
      final err = _errorText(l10n, key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          // Every control fills the column, so a list whose longest option
          // is picked does not make its box jump wider than the rest.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label).semiBold().small()),
                Text(
                  _applies(l10n, key),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
            const Gap(4),
            input,
            if (err != null) ...[
              const Gap(4),
              Text(
                err,
                key: Key('error-$key'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
      );
    }

    /// A typed value that has been changed but not settled yet.
    bool pending(String key) =>
        widget.onApply != null && widget.state.toPatch().containsKey(key);

    Widget settle(String key, Widget input, SettingsFormState Function() undo) {
      if (widget.onApply == null) return input;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: input),
          if (pending(key)) ...[
            const Gap(6),
            IconButton.primary(
              key: Key('apply-$key'),
              density: ButtonDensity.icon,
              icon: const Icon(LucideIcons.check, size: 15),
              onPressed: () => widget.onApply!(widget.state, key),
            ),
            const Gap(4),
            IconButton.outline(
              key: Key('reset-$key'),
              density: ButtonDensity.icon,
              icon: const Icon(LucideIcons.x, size: 15),
              onPressed: () => widget.onChanged(undo()),
            ),
          ],
        ],
      );
    }

    Widget number(String key, String label) => field(
      key,
      label,
      settle(
        key,
        TextField(
          key: Key('field-$key'),
          controller: _controller(key, widget.state.numbers[key] ?? ''),
          enabled: !widget.locked.contains(key),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
          ],
          onChanged: (v) => widget.onChanged(widget.state.setNumber(key, v)),
          onSubmitted: widget.onApply == null
              ? null
              : (_) {
                  if (pending(key)) widget.onApply!(widget.state, key);
                },
        ),
        () => widget.state.setNumber(key, widget.state.originalNumber(key)),
      ),
    );

    Widget flag(String key, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Switch(
            key: Key('field-$key'),
            value: widget.state.flags[key] ?? false,
            onChanged: widget.locked.contains(key)
                ? null
                : (v) {
                    final next = widget.state.setFlag(key, v);
                    widget.onChanged(next);
                    widget.onApply?.call(next, key);
                  },
          ),
          const Gap(8),
          Expanded(child: Text(label)),
          Text(
            _applies(l10n, key),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );

    Widget choice(
      String key,
      String label,
      String value,
      List<(String, String)> options,
      SettingsFormState Function(String) pick,
    ) => field(
      key,
      label,
      Select<String>(
        key: Key('field-$key'),
        value: value,
        itemBuilder: (context, item) =>
            Text(options.firstWhere((o) => o.$1 == item).$2),
        enabled: !widget.locked.contains(key),
        onChanged: (v) {
          if (v == null) return;
          final next = pick(v);
          widget.onChanged(next);
          widget.onApply?.call(next, key);
        },
        popup: SelectPopup<String>(
          items: SelectItemList(
            children: [
              for (final o in options)
                SelectItemButton(value: o.$1, child: Text(o.$2)),
            ],
          ),
        ).call,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showName)
          field(
            'name',
            l10n.adminTableName,
            TextField(
              key: const Key('field-name'),
              initialValue: widget.state.name,
              maxLength: 40,
              autofocus: true,
              onChanged: (v) =>
                  widget.onChanged(widget.state.copyWith(name: v)),
            ),
          ),
        field(
          'password',
          l10n.setPassword,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('field-password'),
                controller: _controller('password', widget.state.password),
                obscureText: true,
                enabled: !widget.state.clearPassword,
                onChanged: (v) =>
                    widget.onChanged(widget.state.copyWith(password: v)),
              ),
              if (widget.showPasswordKeepHint) ...[
                const Gap(4),
                Text(
                  l10n.setPasswordKeep,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                if (widget.state.original.requiresPassword)
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('field-clear-password'),
                        state: widget.state.clearPassword
                            ? CheckboxState.checked
                            : CheckboxState.unchecked,
                        onChanged: (v) => widget.onChanged(
                          widget.state.copyWith(
                            clearPassword: v == CheckboxState.checked,
                          ),
                        ),
                      ),
                      const Gap(6),
                      Text(l10n.setPasswordClear).small(),
                    ],
                  ),
              ],
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final two = c.maxWidth > 560;
            final items = <Widget>[
              choice('variant', l10n.setVariant, widget.state.variant, [
                ('holdem', l10n.variantHoldem),
                ('royal', l10n.variantRoyal),
              ], (v) => widget.state.copyWith(variant: v)),
              number('max_players', l10n.setMaxPlayers),
              number('start_money', l10n.setStartMoney),
              number('small_blind', l10n.setSmallBlind),
              number('big_blind', l10n.setBigBlind),
              number('ante', l10n.setAnte),
              number('turn_time', l10n.setTurnTime),
              number('disconnected_turn_time', l10n.setDisconnectedTurnTime),
              number('sit_out_after_missed_turns', l10n.setSitOutAfter),
              number('hand_delay_ms', l10n.setHandDelay),
              number('blinds_up_minutes', l10n.setBlindsUpMinutes),
              number('blinds_up_percent', l10n.setBlindsUpPercent),
              number('time_bank_seconds', l10n.setTimeBank),
              number('time_bank_refill_seconds', l10n.setTimeBankRefill),
              choice(
                'join_policy',
                l10n.setJoinPolicy,
                widget.state.joinPolicy,
                [
                  ('always', l10n.joinPolicyAlways),
                  ('before_start', l10n.joinPolicyBeforeStart),
                  ('closed', l10n.joinPolicyClosed),
                ],
                (v) => widget.state.copyWith(joinPolicy: v),
              ),
              choice(
                'showdown_reveal',
                l10n.setShowdownReveal,
                widget.state.showdownReveal,
                [
                  ('in_order', l10n.revealInOrder),
                  ('all', l10n.revealAll),
                  ('winners_only', l10n.revealWinnersOnly),
                ],
                (v) => widget.state.copyWith(showdownReveal: v),
              ),
            ];
            if (!two) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              );
            }
            final rows = <Widget>[];
            for (var i = 0; i < items.length; i += 2) {
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: items[i]),
                    const Gap(16),
                    Expanded(
                      child: i + 1 < items.length
                          ? items[i + 1]
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          },
        ),
        _TableType(
          tournament: widget.state.flags['tournament'] ?? false,
          locked: widget.locked.contains('tournament'),
          hint: l10n.setTournament,
          applies: _applies(l10n, 'tournament'),
          // Turning a table into a tournament is a one-way door once a
          // hand is dealt, so it asks first — but only when the switch is
          // being made live; making a new table is not the same thing.
          onPick: (v) async {
            if (v && widget.onApply != null) {
              final yes = await showConfirmDialog(
                context,
                title: l10n.tableTypeTournamentTitle,
                body: l10n.tableTypeTournamentConfirm,
                confirmLabel: l10n.tableTypeTournament,
                cancelLabel: l10n.cancel,
              );
              if (!yes) return;
            }
            final next = widget.state.setFlag('tournament', v);
            widget.onChanged(next);
            widget.onApply?.call(next, 'tournament');
          },
        ),
        flag('allow_spectators', l10n.setAllowSpectators),
        flag('spectator_chat', l10n.setSpectatorChat),
        flag('chat_enabled', l10n.setChatEnabled),
        flag('allow_rebuy', l10n.setAllowRebuy),
        flag('allow_rabbit_hunt', l10n.setAllowRabbitHunt),
        flag('allow_drawing', l10n.setAllowDrawing),
        flag('allow_straddle', l10n.setAllowStraddle),
        flag('run_it_twice', l10n.setRunItTwice),
        flag('auto_start', l10n.setAutoStart),
      ],
    );
  }
}

/// The table's type. A tournament is not one preference among others — it
/// changes what the whole table is and locks most of the rest once a hand
/// is dealt — so it gets a control that looks like a decision.
class _TableType extends StatelessWidget {
  const _TableType({
    required this.tournament,
    required this.locked,
    required this.hint,
    required this.applies,
    required this.onPick,
  });

  final bool tournament;
  final bool locked;
  final String hint;
  final String applies;
  final void Function(bool) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget option(String label, bool value, IconData icon) => Expanded(
      child: (value == tournament ? PrimaryButton.new : OutlineButton.new)(
        key: Key('table-type-${value ? 'tournament' : 'cash'}'),
        enabled: !locked,
        onPressed: () {
          if (value != tournament) onPick(value);
        },
        leading: Icon(icon, size: 14),
        child: Text(label),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.setTableType).semiBold().small()),
              Text(
                applies,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          const Gap(4),
          Row(
            children: [
              option(l10n.tableTypeCash, false, LucideIcons.coins),
              const Gap(8),
              option(l10n.tableTypeTournament, true, LucideIcons.trophy),
            ],
          ),
          const Gap(4),
          Text(
            locked ? l10n.tableTypeLocked : hint,
            key: const Key('table-type-hint'),
          ).muted().xSmall(),
        ],
      ),
    );
  }
}
