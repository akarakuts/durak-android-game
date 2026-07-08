import '../models/card.dart';
import '../models/game.dart';

class AIService {
  PlayingCard? selectDefenseCard(
    List<PlayingCard> hand,
    PlayingCard attackCard,
    Suit? trumpSuit,
  ) {
    final playable =
        hand.where((card) => _canBeat(attackCard, card, trumpSuit)).toList();

    if (playable.isEmpty) return null;

    playable.sort((a, b) {
      if (a.suit == trumpSuit && b.suit != trumpSuit) return 1;
      if (a.suit != trumpSuit && b.suit == trumpSuit) return -1;
      return a.rankValue.compareTo(b.rankValue);
    });

    return playable.first;
  }

  bool _canBeat(PlayingCard attack, PlayingCard defense, Suit? trumpSuit) {
    if (defense.suit == attack.suit) {
      return defense.rankValue > attack.rankValue;
    }
    if (trumpSuit != null && defense.suit == trumpSuit) {
      return true;
    }
    return false;
  }

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
      if (tc.defenseCard != null) {
        ranksOnTable.add(tc.defenseCard!.rank);
      }
    }

    final playable =
        hand.where((card) => ranksOnTable.contains(card.rank)).toList();

    if (playable.isEmpty) return null;

    return _selectBestAttackCard(playable, trumpSuit);
  }

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

  PlayingCard _selectBestAttackCard(
      List<PlayingCard> playable, Suit? trumpSuit) {
    final nonTrump = playable.where((c) => c.suit != trumpSuit).toList();
    if (nonTrump.isNotEmpty) {
      nonTrump.sort((a, b) => a.rankValue.compareTo(b.rankValue));
      return nonTrump.first;
    }

    final sorted = List<PlayingCard>.of(playable)
      ..sort((a, b) => a.rankValue.compareTo(b.rankValue));
    return sorted.first;
  }
}
