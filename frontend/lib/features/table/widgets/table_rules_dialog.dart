import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../core/formatting.dart';
import '../../../protocol/protocol.dart';

/// How the table is set up, for a player who just joined (and again from
/// the Settings tab): the game, the options, tournament or cash game, and
/// what the host can do about chips and settings.
Future<void> showTableRulesDialog(
  BuildContext context, {
  required Snapshot snapshot,
}) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => TableRulesDialog(snapshot: snapshot),
).future;

class TableRulesDialog extends StatelessWidget {
  const TableRulesDialog({super.key, required this.snapshot});

  final Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final table = snapshot.table;
    final s = table.settings;
    // A tournament locks its money settings and the seats at the first deal.
    final locked =
        s.tournament && (table.state != 'waiting' || table.handNumber > 0);
    String chips(int v) => formatChips(v, locale);

    final variant = switch (s.variant) {
      'royal' => l10n.variantRoyal,
      _ => l10n.variantHoldem,
    };
    final reveal = switch (s.showdownReveal) {
      'all' => l10n.revealAll,
      'winners_only' => l10n.revealWinnersOnly,
      _ => l10n.revealInOrder,
    };
    final joinPolicy = switch (s.joinPolicy) {
      'before_start' => l10n.joinPolicyBeforeStart,
      'closed' => l10n.joinPolicyClosed,
      _ => l10n.joinPolicyAlways,
    };
    final timing = [
      l10n.rulesTurnTime(s.turnTime),
      if (s.timeBankSeconds > 0)
        l10n.rulesTimeBank(s.timeBankSeconds, s.timeBankRefillSeconds),
    ].join(' · ');
    final seats = !s.tournament
        ? l10n.rulesSeatChangeFree
        : locked
        ? l10n.rulesSeatChangeLocked
        : l10n.rulesSeatChangeUntilDeal;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text).semiBold().small(),
    );
    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label).muted().small()),
          const Gap(8),
          Expanded(child: Text(value).small()),
        ],
      ),
    );
    Widget mark(bool on, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              on ? LucideIcons.check : LucideIcons.x,
              size: 14,
              color: on
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
          ),
          const Gap(8),
          Expanded(child: on ? Text(text).small() : Text(text).muted().small()),
        ],
      ),
    );
    final options = [
      (s.allowRebuy, l10n.setAllowRebuy),
      (s.allowStraddle, l10n.setAllowStraddle),
      (s.runItTwice, l10n.setRunItTwice),
      (s.allowRabbitHunt, l10n.setAllowRabbitHunt),
      (s.chatEnabled, l10n.setChatEnabled),
      (s.spectatorChat, l10n.setSpectatorChat),
      (s.allowDrawing, l10n.setAllowDrawing),
      (s.requiresPassword, l10n.rulesPassword),
    ];
    final host = [
      (true, l10n.rulesHostLifecycle),
      (true, l10n.rulesHostModeration),
      (true, l10n.rulesHostTiming),
      (true, l10n.rulesHostBlindsUp),
      (!s.tournament, l10n.rulesHostChips),
      if (!s.tournament)
        (true, l10n.rulesHostMoney)
      else if (locked)
        (false, l10n.rulesHostMoneyLocked)
      else
        (true, l10n.rulesHostMoneyBeforeDeal),
    ];

    // Tournament or cash game, as a box so that it stands out.
    final modeColor = s.tournament
        ? theme.colorScheme.primary
        : theme.colorScheme.mutedForeground;
    final mode = Container(
      key: Key(s.tournament ? 'rules-tournament' : 'rules-cash'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: modeColor.withValues(alpha: s.tournament ? 0.12 : 0.06),
        border: Border.all(color: modeColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.tournament ? LucideIcons.trophy : LucideIcons.coins,
                size: 16,
                color: modeColor,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  s.tournament
                      ? locked
                            ? '${l10n.rulesTournament} · ${l10n.rulesLockedNow}'
                            : l10n.rulesTournament
                      : l10n.rulesCashGame,
                ).semiBold(),
              ),
              if (locked) Icon(LucideIcons.lock, size: 14, color: modeColor),
            ],
          ),
          const Gap(6),
          Text(s.tournament ? l10n.rulesTournamentBody : l10n.rulesCashGameBody)
              .small(),
        ],
      ),
    );

    return AlertDialog(
      title: Text(l10n.rulesTitle),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.rulesIntro(table.name)).muted().small(),
              mode,
              heading(l10n.rulesGame),
              fact(l10n.setVariant, variant),
              fact(
                l10n.rulesBlinds,
                '${chips(s.smallBlind)} / ${chips(s.bigBlind)}',
              ),
              if (s.ante > 0) fact(l10n.setAnte, chips(s.ante)),
              fact(l10n.setStartMoney, chips(s.startMoney)),
              fact(l10n.setMaxPlayers, '${s.maxPlayers}'),
              fact(
                l10n.rulesBlindSchedule,
                s.blindsUpMinutes > 0
                    ? l10n.rulesBlindsUp(s.blindsUpMinutes, s.blindsUpPercent)
                    : l10n.rulesBlindsUpOff,
              ),
              fact(l10n.rulesTiming, timing),
              fact(l10n.setShowdownReveal, reveal),
              fact(l10n.setJoinPolicy, joinPolicy),
              fact(l10n.rulesSeatChange, seats),
              heading(l10n.rulesOptions),
              for (final (on, text) in options) mark(on, text),
              heading(l10n.rulesHost),
              for (final (on, text) in host) mark(on, text),
            ],
          ),
        ),
      ),
      actions: [
        PrimaryButton(
          key: const Key('rules-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
