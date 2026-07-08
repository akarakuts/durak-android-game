import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clubsSix = PlayingCard(suit: Suit.clubs, rank: Rank.six);
  const clubsEight = PlayingCard(suit: Suit.clubs, rank: Rank.eight);
  const clubsAce = PlayingCard(suit: Suit.clubs, rank: Rank.ace);
  const heartsSix = PlayingCard(suit: Suit.hearts, rank: Rank.six);
  const heartsSeven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);
  const heartsAce = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
  const spadesSix = PlayingCard(suit: Suit.spades, rank: Rank.six);
  const spadesSeven = PlayingCard(suit: Suit.spades, rank: Rank.seven);

  final ai = AIService();

  test('открытие: выбирается младшая некозырная карта', () {
    const ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
    const six = PlayingCard(suit: Suit.spades, rank: Rank.six);
    final hand = <PlayingCard>[ace, six];

    final selected = ai.selectAttackCard(hand, const [], Suit.clubs);

    expect(selected, six);
    // Рука не должна измениться.
    expect(hand, [ace, six]);
  });

  test('защита: бьёт младшей некозырной картой той же масти', () {
    final selected = ai.selectDefenseCard(
      const [heartsSix, heartsSeven],
      heartsSix,
      Suit.clubs,
    );

    expect(selected, heartsSeven);
  });

  test('защита: бьёт козырем высокую некозырную атаку', () {
    final selected = ai.selectDefenseCard(
      const [clubsSix],
      heartsAce,
      Suit.clubs,
    );

    expect(selected, clubsSix);
  });

  test('защита: не тратит козырь на низкую некозырную атаку — забирает', () {
    final selected = ai.selectDefenseCard(
      const [clubsSix],
      heartsSix,
      Suit.clubs,
    );

    expect(selected, isNull);
  });

  test('защита: козырную атаку бьёт старшим козырем', () {
    final selected = ai.selectDefenseCard(
      const [clubsSix, clubsEight],
      clubsSix,
      Suit.clubs,
    );

    expect(selected, clubsEight);
  });

  test('подкидывание: подкидывает некозырную карту подходящего ранга', () {
    final selected = ai.selectAttackCard(
      const [heartsSeven, clubsAce],
      const [TableCard(attackCard: spadesSeven)],
      Suit.clubs,
    );

    expect(selected, heartsSeven);
  });

  test('подкидывание: отказывается подкидывать козырь, сберегая его', () {
    final selected = ai.selectAttackCard(
      const [clubsSix],
      const [TableCard(attackCard: spadesSix, defenseCard: heartsSix)],
      Suit.clubs,
    );

    expect(selected, isNull);
  });

  test('подкидывание: не подкидывает карту неподходящего ранга', () {
    final selected = ai.selectAttackCard(
      const [heartsSeven, clubsAce],
      const [TableCard(attackCard: clubsEight)],
      Suit.clubs,
    );

    expect(selected, isNull);
  });
}
