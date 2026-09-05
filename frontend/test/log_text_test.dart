import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/features/table/log_text.dart';
import 'package:showdown/features/table/table_session.dart';
import 'package:showdown/l10n/app_localizations_en.dart';
import 'package:showdown/protocol/protocol.dart';

void main() {
  final l = AppLocalizationsEn();
  const names = {0: 'Alice', 3: 'Bob', 4: 'Carol'};
  String? line(GameEvent e, {int? mySeat}) => logLineText(
    l,
    LogEntry(handNumber: 12, event: e, names: names),
    mySeat: mySeat,
  );

  test('renders hand and table events', () {
    expect(
      line(const GameEvent(seq: 1, ts: 0, kind: 'hand_started', buttonSeat: 3)),
      'Hand #12 starts. Dealer: Bob',
    );
    expect(
      line(
        const GameEvent(
          seq: 2,
          ts: 0,
          kind: 'blind_posted',
          seat: 4,
          blind: 'small',
          amount: 50,
        ),
      ),
      'Carol posts small blind 50',
    );
    expect(
      line(
        const GameEvent(
          seq: 3,
          ts: 0,
          kind: 'action',
          seat: 3,
          action: 'raise',
          amount: 1200,
          allIn: true,
        ),
      ),
      'Bob raises to 1,200 (all-in)',
    );
    expect(
      line(
        const GameEvent(
          seq: 4,
          ts: 0,
          kind: 'action',
          seat: 0,
          action: 'call',
          amount: 200,
        ),
      ),
      'Alice calls 200',
    );
    expect(
      line(
        const GameEvent(
          seq: 5,
          ts: 0,
          kind: 'timeout',
          seat: 4,
          resolvedAs: 'fold',
        ),
      ),
      'Carol times out and folds',
    );
    expect(
      line(
        const GameEvent(
          seq: 6,
          ts: 0,
          kind: 'street_dealt',
          street: 'flop',
          cards: ['Ah', '7c', '2d'],
        ),
      ),
      'Flop: A♥ 7♣ 2♦',
    );
    expect(
      line(
        const GameEvent(
          seq: 7,
          ts: 0,
          kind: 'hole_cards_dealt',
          seat: 0,
          cards: ['As', 'Td'],
        ),
        mySeat: 0,
      ),
      'You are dealt A♠ 10♦',
    );
    expect(
      line(const GameEvent(seq: 8, ts: 0, kind: 'hole_cards_dealt', seat: 3)),
      isNull,
    );
    expect(
      line(
        const GameEvent(
          seq: 9,
          ts: 0,
          kind: 'pot_awarded',
          seat: 0,
          amount: 1200,
          potIndex: 0,
          description: 'Two Pair, Aces and Sevens',
        ),
      ),
      'Alice wins 1,200 (Main pot) with Two Pair, Aces and Sevens',
    );
    expect(
      line(
        const GameEvent(
          seq: 10,
          ts: 0,
          kind: 'pot_awarded',
          seat: 3,
          amount: 400,
          potIndex: 1,
        ),
      ),
      'Bob wins 400 (Side pot 1)',
    );
    expect(
      line(
        const GameEvent(
          seq: 11,
          ts: 0,
          kind: 'hands_revealed',
          reveals: [
            Reveal(seat: 0, cards: ['As', 'Kd'], description: 'Pair of Aces'),
          ],
        ),
      ),
      'Alice shows A♠ K♦ - Pair of Aces',
    );
    expect(
      line(
        const GameEvent(
          seq: 12,
          ts: 0,
          kind: 'player_joined',
          seat: 1,
          name: 'Dan',
        ),
      ),
      'Dan joined (seat 1)',
    );
    expect(
      line(
        const GameEvent(
          seq: 13,
          ts: 0,
          kind: 'chips_adjusted',
          seat: 0,
          delta: -500,
        ),
      ),
      'Admin adjusted chips of Alice by -500',
    );
    expect(
      line(
        const GameEvent(
          seq: 14,
          ts: 0,
          kind: 'settings_changed',
          fields: ['big_blind'],
        ),
      ),
      'Settings changed: big_blind',
    );
    expect(
      line(const GameEvent(seq: 15, ts: 0, kind: 'table_paused')),
      'Table paused',
    );
    expect(line(const GameEvent(seq: 16, ts: 0, kind: 'pots_updated')), isNull);
    expect(
      line(
        const GameEvent(
          seq: 17,
          ts: 0,
          kind: 'action',
          seat: 9,
          action: 'fold',
        ),
      ),
      'Seat 9 folds',
    );
  });
}
