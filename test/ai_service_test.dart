import 'package:durak_game/models/card.dart';
import 'package:durak_game/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('выбор карты не изменяет порядок руки компьютера', () {
    const ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
    const six = PlayingCard(suit: Suit.spades, rank: Rank.six);
    final hand = <PlayingCard>[ace, six];

    final selected = AIService().selectAttackCard(hand, const [], Suit.clubs);

    expect(selected, six);
    expect(hand, [ace, six]);
  });
}
