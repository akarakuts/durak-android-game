import 'card.dart';

enum PlayerType { human, computer }

class Player {
  final String name;
  final PlayerType type;
  final List<PlayingCard> hand;

  Player({
    required this.name,
    required this.type,
    List<PlayingCard>? hand,
  }) : hand = List<PlayingCard>.of(hand ?? const []);

  Player.copy(Player other)
      : name = other.name,
        type = other.type,
        hand = List<PlayingCard>.of(other.hand);

  bool get isEmpty => hand.isEmpty;

  int get cardCount => hand.length;

  void addCards(List<PlayingCard> cards) {
    hand.addAll(cards);
  }

  void removeCard(PlayingCard card) {
    hand.remove(card);
  }

  void sortHand(Suit? trumpSuit) {
    hand.sort((a, b) {
      if (trumpSuit != null) {
        final aIsTrump = a.suit == trumpSuit;
        final bIsTrump = b.suit == trumpSuit;
        if (aIsTrump && !bIsTrump) return 1;
        if (!aIsTrump && bIsTrump) return -1;
        if (aIsTrump && bIsTrump) {
          return a.rankValue.compareTo(b.rankValue);
        }
      }
      if (a.suit != b.suit) {
        return a.suit.index.compareTo(b.suit.index);
      }
      return a.rankValue.compareTo(b.rankValue);
    });
  }

  bool canBeat(
      PlayingCard attackCard, PlayingCard defenseCard, Suit? trumpSuit) {
    if (defenseCard.suit == attackCard.suit) {
      return defenseCard.rankValue > attackCard.rankValue;
    }
    if (trumpSuit != null && defenseCard.suit == trumpSuit) {
      return true;
    }
    return false;
  }
}
