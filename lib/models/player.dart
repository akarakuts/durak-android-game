import 'card.dart';

/// Тип игрока: человек или компьютер.
enum PlayerType { human, computer }

/// Неизменяемый игрок.
///
/// Операции с рукой ([addCards], [removeCard], [sortHand]) возвращают нового
/// игрока, не мутируя текущего.
class Player {
  final String name;
  final PlayerType type;
  final List<PlayingCard> hand;

  Player({
    required this.name,
    required this.type,
    List<PlayingCard>? hand,
  }) : hand = List<PlayingCard>.unmodifiable(hand ?? const []);

  Player._({
    required this.name,
    required this.type,
    required List<PlayingCard> hand,
  }) : hand = List<PlayingCard>.unmodifiable(hand);

  /// Возвращает копию игрока с заменённой рукой.
  Player copyWith({List<PlayingCard>? hand}) =>
      Player._(name: name, type: type, hand: hand ?? this.hand);

  /// Рука пуста.
  bool get isEmpty => hand.isEmpty;

  /// Количество карт в руке.
  int get cardCount => hand.length;

  /// Возвращает нового игрока с добавленными картами.
  Player addCards(List<PlayingCard> cards) =>
      copyWith(hand: [...hand, ...cards]);

  /// Возвращает нового игрока без первого вхождения [card].
  Player removeCard(PlayingCard card) {
    final index = hand.indexOf(card);
    if (index == -1) return this;
    return copyWith(
      hand: [...hand.sublist(0, index), ...hand.sublist(index + 1)],
    );
  }

  /// Возвращает нового игрока с отсортированной рукой.
  ///
  /// Козырные карты уходят в конец; внутри масти сортировка по достоинству.
  Player sortHand(Suit? trumpSuit) => copyWith(hand: _sorted(hand, trumpSuit));

  static List<PlayingCard> _sorted(List<PlayingCard> hand, Suit? trumpSuit) {
    final sorted = List<PlayingCard>.of(hand);
    sorted.sort((a, b) {
      if (trumpSuit != null) {
        final aIsTrump = a.suit == trumpSuit;
        final bIsTrump = b.suit == trumpSuit;
        if (aIsTrump && !bIsTrump) return 1;
        if (!aIsTrump && bIsTrump) return -1;
        if (aIsTrump && bIsTrump) return a.rankValue.compareTo(b.rankValue);
      }
      if (a.suit != b.suit) return a.suit.index.compareTo(b.suit.index);
      return a.rankValue.compareTo(b.rankValue);
    });
    return sorted;
  }

  /// Может ли [defenseCard] побить атакующую [attackCard].
  ///
  /// Бьёт старшей картой той же масти или козырем (если атака не козырная).
  bool canBeat(
    PlayingCard attackCard,
    PlayingCard defenseCard,
    Suit? trumpSuit,
  ) {
    if (defenseCard.suit == attackCard.suit) {
      return defenseCard.rankValue > attackCard.rankValue;
    }
    if (trumpSuit != null && defenseCard.suit == trumpSuit) return true;
    return false;
  }
}
