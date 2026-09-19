import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../app/l10n.dart';
import '../../core/account.dart';
import '../../core/formatting.dart';
import '../../shared/pot_colors.dart';

/// A profile's own record. Private: nobody else can read any of this.
Future<void> showStatsDialog(BuildContext context) => showOverlay<void>(
  context,
  const DialogConfiguration(),
  builder: (context) => const StatsDialog(),
).future;

/// The name of a poker category as the server numbers them (0 high card ..
/// 8 straight flush), with the royal flush apart.
String handClassName(
  AppLocalizations l10n,
  int category, {
  bool royal = false,
}) {
  if (royal) return l10n.handRoyalFlush;
  return switch (category) {
    8 => l10n.handStraightFlush,
    7 => l10n.handFourOfAKind,
    6 => l10n.handFullHouse,
    5 => l10n.handFlush,
    4 => l10n.handStraight,
    3 => l10n.handThreeOfAKind,
    2 => l10n.handTwoPair,
    1 => l10n.handPair,
    _ => l10n.handHighCard,
  };
}

/// The four pages of the record. Money first: everything a player asked
/// for in chips is in chips, and the big-blind figures sit next to their
/// explanation instead of leading the page.
enum StatsTab { overview, results, style, hands }

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
                  StatsTab.hands => _Hands(s),
                },
              ),
            ),
          ],
        );
    }

    return AlertDialog(
      title: Text(l10n.statsTitle),
      content: SizedBox(width: 420, child: body),
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
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis).small(),
        ),
      ],
    ),
  );
}

/// The chip colour of a result: gold for a win, the warning colour for a
/// loss, plain text for a player who is exactly even.
Color? _moneyColor(BuildContext context, num v) => v == 0
    ? null
    : v > 0
    ? potGold
    : Theme.of(context).colorScheme.destructive;

/// A group of figures under an icon and a heading.
class _Group extends StatelessWidget {
  const _Group({required this.icon, required this.title, required this.rows});

  final IconData icon;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 12, color: muted),
                const Gap(6),
                Text(title.toUpperCase()).muted().xSmall().semiBold(),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

/// One label and its figure. [hint] goes under the label in small print,
/// for the rows that would otherwise need explaining.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.hint, this.color});

  final String label;
  final String value;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label).muted().small(),
              if (hint != null) Text(hint!).muted().xSmall(),
            ],
          ),
        ),
        const Gap(8),
        Text(
          value,
          style: TextStyle(fontFamily: 'GeistMono', color: color),
        ),
      ],
    ),
  );
}

/// A share of the hands, told as a number and as a bar.
class _Meter extends StatelessWidget {
  const _Meter(this.label, this.value, this.fraction, {this.color});

  final String label;
  final String value;
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label).muted().small()),
              const Gap(8),
              Text(value, style: const TextStyle(fontFamily: 'GeistMono')),
            ],
          ),
          const Gap(5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              color: theme.colorScheme.muted,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0, 1),
                child: Container(
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _chips(BuildContext context, int v) =>
    formatChips(v, Localizations.localeOf(context).toString());

String _signed(BuildContext context, int v) =>
    (v > 0 ? '+' : '') + _chips(context, v);

String _bb(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)} bb';

String _percent(double v) => '${v.toStringAsFixed(0)} %';

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
        Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.statsNet.toUpperCase()).muted().xSmall().semiBold(),
              const Gap(2),
              Text(
                _signed(context, s.net),
                key: const Key('stats-net'),
                style: TextStyle(
                  fontFamily: 'GeistMono',
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: _moneyColor(context, s.net),
                ),
              ),
              const Gap(2),
              Text(
                l10n.statsOverHands('${s.hands}', '${s.tables}'),
              ).muted().small(),
            ],
          ),
        ),
        const Gap(14),
        _Group(
          icon: LucideIcons.layers,
          title: l10n.statsVolume,
          rows: [
            _Row(l10n.statsHands, '${s.hands}'),
            _Row(l10n.statsTables, '${s.tables}'),
            _Row(l10n.statsRounds, '${s.rounds}'),
            _Row(l10n.statsHandsWon, '${s.handsWon}'),
            if (s.firstHand > 0)
              _Row(l10n.statsFirstHand, formatDate(s.firstHand, locale)),
          ],
        ),
        Text(
          l10n.statsCountedNote('${s.countedHands}', '${s.hands}'),
        ).muted().xSmall(),
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
        _Group(
          icon: LucideIcons.coins,
          title: l10n.statsBest,
          rows: [
            _Row(
              l10n.statsBiggestPot,
              _chips(context, s.biggestPot),
              hint: l10n.statsBiggestPotHint,
            ),
            _Row(
              l10n.statsBiggestWin,
              _signed(context, s.biggestWin),
              color: _moneyColor(context, s.biggestWin),
            ),
            _Row(
              l10n.statsBestRound,
              _signed(context, s.bestRound),
              hint: l10n.statsBestRoundHint,
              color: _moneyColor(context, s.bestRound),
            ),
          ],
        ),
        _Group(
          icon: LucideIcons.trendingUp,
          title: l10n.statsRate,
          rows: [
            _Row(
              l10n.statsPer100Chips,
              _signed(context, per100),
              color: _moneyColor(context, per100),
            ),
            _Row(
              l10n.statsNetBB,
              _bb(s.netBB),
              hint: l10n.statsBbHint,
              color: _moneyColor(context, s.netBB),
            ),
            _Row(
              l10n.statsPer100,
              _bb(s.bbPer100),
              color: _moneyColor(context, s.bbPer100),
            ),
          ],
        ),
        if (s.rounds > 0)
          _Group(
            icon: LucideIcons.medal,
            title: l10n.statsRounds,
            rows: [
              _Row(l10n.statsRoundsWon, '${s.roundsWon}'),
              _Row(l10n.statsPodiums, '${s.podiums}'),
              if (s.tournaments > 0)
                _Row(l10n.statsTournaments, '${s.tournaments}'),
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
        _Group(
          icon: LucideIcons.gauge,
          title: l10n.statsStyle,
          rows: [
            _Meter(
              l10n.statsVpip,
              _percent(s.vpipPercent),
              s.vpipPercent / 100,
            ),
            _Meter(
              l10n.statsFolded,
              _percent(s.foldPercent),
              s.foldPercent / 100,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
        _Group(
          icon: LucideIcons.eye,
          title: l10n.statsShowdownGroup,
          rows: [
            _Meter(
              l10n.statsShowdowns,
              '${s.showdownsWon}/${s.showdowns} · '
              '${_percent(s.showdownWinPercent)}',
              s.showdownWinPercent / 100,
              color: potGold,
            ),
            _Row(l10n.statsNoShowdown, '${s.wonWithoutShowdown}'),
            _Row(l10n.statsAllIns, '${s.allIns}'),
          ],
        ),
      ],
    );
  }
}

/// The hands the profile made, most valuable first, with the ones the
/// table got to see.
class _Hands extends StatelessWidget {
  const _Hands(this.s);

  final ProfileStats s;

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
    return _Group(
      icon: LucideIcons.spade,
      title: l10n.statsHandClasses,
      rows: [
        for (final c in s.handClasses)
          _Meter(
            handClassName(l10n, c.category, royal: c.royal),
            c.shown > 0
                ? '${c.made}  (${l10n.statsShownOf('${c.shown}')})'
                : '${c.made}',
            c.made / most,
            color: c.royal || c.category >= 5 ? potGold : null,
          ),
      ],
    );
  }
}
