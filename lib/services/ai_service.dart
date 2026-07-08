import '../models/card.dart';
import '../models/game.dart';

/// Простой жадный ИИ противника с осмысленными эвристиками.
///
/// Эвристики:
/// * Защита: бьёт младшей некозырной картой; козырь тратит только при
///   необходимости и не на низкие некозырные атаки (лучше забрать).
/// * Атака открытием: ходит младшей некозырной картой.
/// * Подкидывание: подкидывает только некозырные карты подходящего ранга;
///   если таких нет — отказывается от подкидывания, сберегая козыри.
class AIService {
  /// Порог «низкой» атаки: шестёрка–восьмёрка.
  static const int _lowRankThreshold = 8;

  /// Выбирает карту для защиты от [attackCard] или null, если решает забрать.
  PlayingCard? selectDefenseCard(
    List<PlayingCard> hand,
    PlayingCard attackCard,
    Suit? trumpSuit,
  ) {
    final beatable =
        hand.where((card) => _canBeat(attackCard, card, trumpSuit)).toList();

    if (beatable.isEmpty) return null;

    // Предпочитаем некозырную карту — бьём младшей такой.
    final nonTrump = beatable.where((c) => c.suit != trumpSuit).toList();
    if (nonTrump.isNotEmpty) {
      nonTrump.sort((a, b) => a.rankValue.compareTo(b.rankValue));
      return nonTrump.first;
    }

    // Остались только козыри. Не тратить козырь на низкую некозырную атаку —
    // выгоднее забрать карты.
    final isTrumpAttack = attackCard.suit == trumpSuit;
    if (!isTrumpAttack && attackCard.rankValue <= _lowRankThreshold) {
      return null;
    }
    final trumps = List<PlayingCard>.of(beatable)
      ..sort((a, b) => a.rankValue.compareTo(b.rankValue));
    return trumps.first;
  }

  bool _canBeat(PlayingCard attack, PlayingCard defense, Suit? trumpSuit) {
    if (defense.suit == attack.suit) {
      return defense.rankValue > attack.rankValue;
    }
    if (trumpSuit != null && defense.suit == trumpSuit) return true;
    return false;
  }

  /// Выбирает карту для атаки или null, если подкидывать нечем/незачем.
  PlayingCard? selectAttackCard(
    List<PlayingCard> hand,
    List<TableCard> tableCards,
    Suit? trumpSuit,
  ) {
    if (hand.isEmpty) return null;

    if (tableCards.isEmpty) {
      return _selectBestOpeningCard(hand, trumpSuit);
    }

    final ranksOnTable = <Rank>{};
    for (final tc in tableCards) {
      ranksOnTable.add(tc.attackCard.rank);
      if (tc.defenseCard != null) ranksOnTable.add(tc.defenseCard!.rank);
    }

    final playable =
        hand.where((card) => ranksOnTable.contains(card.rank)).toList();

    if (playable.isEmpty) return null;

    // Подкидываем только некозырные карты; козыри сберегаем.
    final nonTrump = playable.where((c) => c.suit != trumpSuit).toList();
    if (nonTrump.isEmpty) return null;

    nonTrump.sort((a, b) => a.rankValue.compareTo(b.rankValue));
    return nonTrump.first;
  }

  /// Младшая некозырная карта для первого хода; иначе младший козырь.
  PlayingCard _selectBestOpeningCard(List<PlayingCard> hand, Suit? trumpSuit) {
    final nonTrump = hand.where((c) => c.suit != trumpSuit).toList();
    if (nonTrump.isNotEmpty) {
      nonTrump.sort((a, b) => a.rankValue.compareTo(b.rankValue));
      return nonTrump.first;
    }

    final sorted = List<PlayingCard>.of(hand)
      ..sort((a, b) => a.rankValue.compareTo(b.rankValue));
    return sorted.first;
  }
}
