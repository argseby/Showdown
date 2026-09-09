import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import 'settings_form_model.dart';

/// The §5.2 settings form. [state] is owned by the caller; every change is
/// reported through [onChanged]. [serverErrors] come from the API response.
class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.state,
    required this.onChanged,
    required this.errors,
    this.serverErrors = const {},
    this.showName = false,
    this.showPasswordKeepHint = false,
    this.seated = 0,
  });

  final SettingsFormState state;
  final ValueChanged<SettingsFormState> onChanged;
  final Map<String, SettingsError> errors;
  final Map<String, String> serverErrors;
  final bool showName;
  final bool showPasswordKeepHint;
  final int seated;

  String? _errorText(AppLocalizations l10n, String field) {
    final server = serverErrors[field];
    if (server != null) return server;
    switch (errors[field]) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

    Widget number(String key, String label) => field(
      key,
      label,
      TextField(
        key: Key('field-$key'),
        initialValue: state.numbers[key],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
        onChanged: (v) => onChanged(state.setNumber(key, v)),
      ),
    );

    Widget flag(String key, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Switch(
            key: Key('field-$key'),
            value: state.flags[key] ?? false,
            onChanged: (v) => onChanged(state.setFlag(key, v)),
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
      ValueChanged<String> onSelect,
    ) => field(
      key,
      label,
      Select<String>(
        key: Key('field-$key'),
        value: value,
        itemBuilder: (context, item) =>
            Text(options.firstWhere((o) => o.$1 == item).$2),
        onChanged: (v) {
          if (v != null) onSelect(v);
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
        if (showName)
          field(
            'name',
            l10n.adminTableName,
            TextField(
              key: const Key('field-name'),
              initialValue: state.name,
              maxLength: 40,
              autofocus: true,
              onChanged: (v) => onChanged(state.copyWith(name: v)),
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
                initialValue: state.password,
                obscureText: true,
                enabled: !state.clearPassword,
                onChanged: (v) => onChanged(state.copyWith(password: v)),
              ),
              if (showPasswordKeepHint) ...[
                const Gap(4),
                Text(
                  l10n.setPasswordKeep,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                if (state.original.requiresPassword)
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('field-clear-password'),
                        state: state.clearPassword
                            ? CheckboxState.checked
                            : CheckboxState.unchecked,
                        onChanged: (v) => onChanged(
                          state.copyWith(
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
              choice('variant', l10n.setVariant, state.variant, [
                ('holdem', l10n.variantHoldem),
                ('royal', l10n.variantRoyal),
              ], (v) => onChanged(state.copyWith(variant: v))),
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
              choice('join_policy', l10n.setJoinPolicy, state.joinPolicy, [
                ('always', l10n.joinPolicyAlways),
                ('before_start', l10n.joinPolicyBeforeStart),
                ('closed', l10n.joinPolicyClosed),
              ], (v) => onChanged(state.copyWith(joinPolicy: v))),
              choice(
                'showdown_reveal',
                l10n.setShowdownReveal,
                state.showdownReveal,
                [
                  ('in_order', l10n.revealInOrder),
                  ('all', l10n.revealAll),
                  ('winners_only', l10n.revealWinnersOnly),
                ],
                (v) => onChanged(state.copyWith(showdownReveal: v)),
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
        flag('allow_spectators', l10n.setAllowSpectators),
        flag('spectator_chat', l10n.setSpectatorChat),
        flag('chat_enabled', l10n.setChatEnabled),
        flag('allow_rebuy', l10n.setAllowRebuy),
        flag('allow_rabbit_hunt', l10n.setAllowRabbitHunt),
        flag('allow_straddle', l10n.setAllowStraddle),
        flag('run_it_twice', l10n.setRunItTwice),
        flag('auto_start', l10n.setAutoStart),
      ],
    );
  }
}
