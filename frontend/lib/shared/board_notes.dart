import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../app/l10n.dart';
import '../protocol/protocol.dart';
import 'playing_card.dart';

/// The board, read back in words: what it threatens for anyone holding the
/// right two cards, and what the hand looking at it can still become.
///
/// This is the half a percentage cannot carry. "You win 86%" is a number;
/// "three hearts out there — anyone with two more has a flush" is the
/// reason, and the reason is the thing a player takes to the next hand.
/// The notes stay observations: none of them says what to do, and the one
/// about a scary board says out loud that it is scary for the opponents
/// too — a board nobody can call on is a board worth betting.
String? noteText(AppLocalizations l10n, HandNote note) {
  final suit = switch (note.suit) {
    's' => l10n.suitSpades,
    'h' => l10n.suitHearts,
    'd' => l10n.suitDiamonds,
    'c' => l10n.suitClubs,
    _ => note.suit ?? '',
  };
  final rank = rankWord(l10n, note.rank);
  return switch (note.id) {
    'nuts' => l10n.noteNuts,
    'flush_draw' => l10n.noteFlushDraw(suit),
    'open_ended' => l10n.noteOpenEnded,
    'gutshot' => l10n.noteGutshot,
    'flush_possible' => l10n.noteFlushPossible(suit),
    'flush_landed' => l10n.noteFlushLanded(suit),
    'straight_possible' => l10n.noteStraightPossible,
    'board_paired' => l10n.noteBoardPaired(rank),
    'overcard' => l10n.noteOvercard(oneRankWord(l10n, note.rank)),
    'scary_for_everyone' => l10n.noteScaryForEveryone,
    // An id this client does not know yet is a note for a newer client,
    // not a reason to show the player a raw word.
    _ => null,
  };
}

/// One card of the rank ("King on the board"). Kept apart from the plural
/// because a sentence needs one or the other and never both — and because
/// German gives each rank its own article, which is why no note puts one
/// in front of this.
String oneRankWord(AppLocalizations l10n, String? rank) => switch (rank) {
  '2' => l10n.rankOneTwo,
  '3' => l10n.rankOneThree,
  '4' => l10n.rankOneFour,
  '5' => l10n.rankOneFive,
  '6' => l10n.rankOneSix,
  '7' => l10n.rankOneSeven,
  '8' => l10n.rankOneEight,
  '9' => l10n.rankOneNine,
  'T' => l10n.rankOneTen,
  'J' => l10n.rankOneJack,
  'Q' => l10n.rankOneQueen,
  'K' => l10n.rankOneKing,
  'A' => l10n.rankOneAce,
  _ => rank ?? '',
};

/// The rank as the plural a sentence wants ("a pair of Sevens"). The
/// server sends the one-character spelling the cards use.
String rankWord(AppLocalizations l10n, String? rank) => switch (rank) {
  '2' => l10n.rankTwos,
  '3' => l10n.rankThrees,
  '4' => l10n.rankFours,
  '5' => l10n.rankFives,
  '6' => l10n.rankSixes,
  '7' => l10n.rankSevens,
  '8' => l10n.rankEights,
  '9' => l10n.rankNines,
  'T' => l10n.rankTens,
  'J' => l10n.rankJacks,
  'Q' => l10n.rankQueens,
  'K' => l10n.rankKings,
  'A' => l10n.rankAces,
  _ => rank ?? '',
};

/// The hand a player is holding, in their own language. The server sends
/// the category and the ranks that name it; the English sentence it also
/// sends is for the log and for hands other players reveal, not for the
/// one place a player reads about their own.
///
/// Before the flop the two cards are the hand: a pocket pair, or the two
/// ranks with suited or offsuit after them.
String handName(
  AppLocalizations l10n, {
  required int category,
  required List<String> ranks,
  bool royal = false,
  bool preflop = false,
  bool suited = false,
}) {
  String one(int i) => i < ranks.length ? oneRankWord(l10n, ranks[i]) : '';
  String many(int i) => i < ranks.length ? rankWord(l10n, ranks[i]) : '';
  if (preflop) {
    if (ranks.length < 2) return l10n.handPairOf(many(0));
    return suited
        ? l10n.handStartSuited(one(0), one(1))
        : l10n.handStartOffsuit(one(0), one(1));
  }
  if (royal) return l10n.handRoyalFlush;
  return switch (category) {
    1 => l10n.handPairOf(many(0)),
    2 => l10n.handTwoPairOf(many(0), many(1)),
    3 => l10n.handTripsOf(many(0)),
    4 => l10n.handStraightTo(one(0)),
    5 => l10n.handFlushTo(one(0)),
    6 => l10n.handFullHouseOf(many(0), many(1)),
    7 => l10n.handQuadsOf(many(0)),
    8 => l10n.handStraightFlushTo(one(0)),
    _ => l10n.handHighCardOf(one(0)),
  };
}

/// What a note is about, which decides how it is drawn. A warning and a
/// draw are opposite news and should not look alike.
enum NoteTone {
  /// Something the board hands the opponents.
  threat,

  /// Something this hand can still become.
  draw,

  /// Something this hand already is.
  made,

  /// A remark about the board that cuts both ways.
  balance,
}

/// The tone and icon of a note, by its id.
(NoteTone, IconData) noteLook(String id) => switch (id) {
  'nuts' => (NoteTone.made, LucideIcons.crown),
  'flush_draw' ||
  'open_ended' ||
  'gutshot' => (NoteTone.draw, LucideIcons.trendingUp),
  'scary_for_everyone' => (NoteTone.balance, LucideIcons.swords),
  _ => (NoteTone.threat, LucideIcons.triangleAlert),
};

/// The colour a tone is drawn in: teal for what is yours or coming, amber
/// for what the board owes the others, muted for the even-handed remark.
Color noteColor(BuildContext context, NoteTone tone) => switch (tone) {
  NoteTone.made => const Color(0xFFE6B422),
  NoteTone.draw => handRing,
  NoteTone.threat => const Color(0xFFE0A106),
  NoteTone.balance => Theme.of(context).colorScheme.mutedForeground,
};

/// The notes as lines under the hand, at most as many as the server sent.
/// Nothing at all before the flop, which is where most hands are decided
/// and where there is nothing yet to read.
class BoardNotes extends StatelessWidget {
  const BoardNotes({
    super.key,
    required this.notes,
    this.compact = false,
    this.align = TextAlign.center,
  });

  final List<HandNote> notes;
  final bool compact;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Kept in step: a note the client has no words for drops out of both
    // lists, so the icons never slide off their sentences.
    final shown = [
      for (final note in notes)
        if (noteText(l10n, note) != null) note,
    ];
    final lines = [for (final note in shown) noteText(l10n, note)!];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('board-notes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, text) in lines.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final (tone, icon) = noteLook(shown[i].id);
                    return Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        icon,
                        size: 12,
                        color: noteColor(context, tone),
                      ),
                    );
                  },
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
