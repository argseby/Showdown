import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../shared/pot_colors.dart';
import 'stats_parts.dart';

/// A profile's own record. Private: nobody else can read any of this.
Future<void> showStatsDialog(BuildContext context) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => const StatsDialog(),
).future;

enum StatsTab { overview, results, style, hands, awards }

class StatsDialog extends ConsumerStatefulWidget {
  const StatsDialog({super.key});

  @override
  ConsumerState<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends ConsumerState<StatsDialog> {
  StatsTab _tab = StatsTab.overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = ref.watch(accountStatsProvider);
    final highlights =
        ref.watch(accountHighlightsProvider).value ?? const ProfileHighlights();

    Widget body;
    switch (stats) {
      case AsyncLoading():
        body = const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        );
      case AsyncError():
        body = SizedBox(
          height: 160,
          child: Center(child: Text(l10n.errGeneric('')).muted().small()),
        );
      case AsyncData(:final value):
        final s = value ?? const ProfileStats();
        if (s.empty) {
          body = SizedBox(
            height: 160,
            child: Center(
              child: Text(
                l10n.statsEmpty,
                key: const Key('stats-empty'),
                textAlign: TextAlign.center,
              ).muted(),
            ),
          );
          break;
        }
        body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tabs(
              index: _tab.index,
              onChanged: (i) => setState(() => _tab = StatsTab.values[i]),
              // Four tabs across the dialog: the default padding would
              // push the last two off its edge.
              expand: true,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              children: [
                _tabItem(
                  const Key('stats-tab-overview'),
                  LucideIcons.layoutDashboard,
                  l10n.statsTabOverview,
                ),
                _tabItem(
                  const Key('stats-tab-results'),
                  LucideIcons.trophy,
                  l10n.statsMoney,
                ),
                _tabItem(
                  const Key('stats-tab-style'),
                  LucideIcons.gauge,
                  l10n.statsStyle,
                ),
                _tabItem(
                  const Key('stats-tab-hands'),
                  LucideIcons.spade,
                  l10n.statsTabHands,
                ),
                _tabItem(
                  const Key('stats-tab-awards'),
                  LucideIcons.award,
                  l10n.statsTabAwards,
                ),
              ],
            ),
            const Gap(14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: switch (_tab) {
                  StatsTab.overview => _Overview(s),
                  StatsTab.results => _Results(s),
                  StatsTab.style => _Style(s),
                  StatsTab.hands => _Hands(s, highlights),
                  StatsTab.awards => _Awards(highlights),
                },
              ),
            ),
          ],
        );
    }

    return AlertDialog(
      title: Text(l10n.statsTitle),
      content: SizedBox(width: 470, child: body),
      actions: [
        PrimaryButton(
          key: const Key('stats-close'),
          onPressed: () => closeOverlay<void>(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  TabItem _tabItem(Key key, IconData icon, String label) => TabItem(
    key: key,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const Gap(5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis).small()),
      ],
    ),
  );
}

/// The headline: what the profile is up or down, in chips.
class _Overview extends StatelessWidget {
  const _Overview(this.s);

  final ProfileStats s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NetHero(
          net: s.net,
          caption: l10n.statsOverHands('${s.hands}', '${s.tables}'),
        ),
        const Gap(14),
        StatsGroup(
          icon: LucideIcons.layers,
          title: l10n.statsVolume,
          rows: [
            StatsRow(l10n.statsHands, '${s.hands}'),
            StatsRow(l10n.statsTables, '${s.tables}'),
            StatsRow(l10n.statsRounds, '${s.rounds}'),
            StatsRow(l10n.statsHandsWon, '${s.handsWon}'),
            if (s.firstHand > 0)
              StatsRow(l10n.statsFirstHand, formatDate(s.firstHand, locale)),
          ],
        ),
      ],
    );
  }
}

/// Everything about the money, chips first and big blinds explained.
class _Results extends StatelessWidget {
  const _Results(this.s);

  final ProfileStats s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Chips per 100 hands: the same rate as bb/100, in the currency the
    // player actually sees at the table.
    final per100 = s.hands == 0 ? 0 : (s.net * 100 / s.hands).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StatsGroup(
          icon: LucideIcons.coins,
          title: l10n.statsBest,
          rows: [
            StatsRow(
              l10n.statsBiggestPot,
              chipsText(context, s.biggestPot),
              hint: l10n.statsBiggestPotHint,
            ),
            StatsRow(
              l10n.statsBiggestWin,
              signedChips(context, s.biggestWin),
              color: moneyColor(context, s.biggestWin),
            ),
            StatsRow(
              l10n.statsBestRound,
              signedChips(context, s.bestRound),
              hint: l10n.statsBestRoundHint,
              color: moneyColor(context, s.bestRound),
            ),
          ],
        ),
        StatsGroup(
          icon: LucideIcons.trendingUp,
          title: l10n.statsRate,
          rows: [
            StatsRow(
              l10n.statsPer100Chips,
              signedChips(context, per100),
              color: moneyColor(context, per100),
            ),
            StatsRow(
              l10n.statsNetBB,
              bbText(s.netBB),
              hint: l10n.statsBbHint,
              color: moneyColor(context, s.netBB),
            ),
            StatsRow(
              l10n.statsPer100,
              bbText(s.bbPer100),
              color: moneyColor(context, s.bbPer100),
            ),
          ],
        ),
        if (s.rounds > 0)
          StatsGroup(
            icon: LucideIcons.medal,
            title: l10n.statsRounds,
            rows: [
              StatsRow(l10n.statsRoundsWon, '${s.roundsWon}'),
              StatsRow(l10n.statsPodiums, '${s.podiums}'),
              if (s.tournaments > 0)
                StatsRow(l10n.statsTournaments, '${s.tournaments}'),
            ],
          ),
      ],
    );
  }
}

/// How the profile plays, as shares of the hands it was dealt.
class _Style extends StatelessWidget {
  const _Style(this.s);

  final ProfileStats s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StatsGroup(
          icon: LucideIcons.gauge,
          title: l10n.statsStyle,
          rows: [
            StatsMeter(
              l10n.statsVpip,
              percentText(s.vpipPercent),
              s.vpipPercent / 100,
            ),
            StatsMeter(
              l10n.statsFolded,
              percentText(s.foldPercent),
              s.foldPercent / 100,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
        StatsGroup(
          icon: LucideIcons.eye,
          title: l10n.statsShowdownGroup,
          rows: [
            StatsMeter(
              l10n.statsShowdowns,
              '${s.showdownsWon}/${s.showdowns} · '
              '${percentText(s.showdownWinPercent)}',
              s.showdownWinPercent / 100,
              color: potGold,
            ),
            StatsRow(l10n.statsNoShowdown, '${s.wonWithoutShowdown}'),
            StatsRow(l10n.statsAllIns, '${s.allIns}'),
          ],
        ),
      ],
    );
  }
}

/// The hands the profile made, most valuable first, with the ones the
/// table got to see.
class _Hands extends StatelessWidget {
  const _Hands(this.s, this.highlights);

  final ProfileStats s;
  final ProfileHighlights highlights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (s.handClasses.isEmpty) {
      return Text(l10n.statsNoHandsYet).muted().small();
    }
    var most = 1;
    for (final c in s.handClasses) {
      if (c.made > most) most = c.made;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StatsGroup(
          icon: LucideIcons.spade,
          title: l10n.statsHandClasses,
          rows: [
            for (final c in s.handClasses)
              StatsMeter(
                handClassName(l10n, c.category, royal: c.royal),
                c.shown > 0
                    ? '${c.made}  (${l10n.statsShownOf('${c.shown}')})'
                    : '${c.made}',
                c.made / most,
                color: c.royal || c.category >= 5 ? potGold : null,
              ),
          ],
        ),
        if (highlights.bestHands.isNotEmpty)
          StatsGroup(
            icon: LucideIcons.crown,
            title: l10n.statsBestHands,
            rows: [for (final h in highlights.bestHands.take(5)) HandCard(h)],
          ),
        if (highlights.biggestWins.isNotEmpty)
          StatsGroup(
            icon: LucideIcons.coins,
            title: l10n.statsBiggestPots,
            rows: [for (final h in highlights.biggestWins.take(5)) HandCard(h)],
          ),
      ],
    );
  }
}

/// The milestones: what has been earned, and what is still ahead.
class _Awards extends StatelessWidget {
  const _Awards(this.highlights);

  final ProfileHighlights highlights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earned = highlights.earned;
    final ahead = highlights.ahead;
    if (earned.isEmpty && ahead.isEmpty) {
      return Text(l10n.statsEmpty).muted().small();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (earned.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.statsNoAwardsYet).muted().small(),
          )
        else
          StatsGroup(
            icon: LucideIcons.award,
            title: l10n.statsTabAwards,
            rows: [for (final a in earned) AwardRow(a, earned: true)],
          ),
        if (ahead.isNotEmpty)
          StatsGroup(
            icon: LucideIcons.target,
            title: l10n.statsAwardsAhead,
            rows: [for (final a in ahead) AwardRow(a, earned: false)],
          ),
      ],
    );
  }
}
