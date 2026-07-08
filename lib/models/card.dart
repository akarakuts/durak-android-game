/// Масть игральной карты.
enum Suit { clubs, diamonds, hearts, spades }

/// Достоинство карты от шестёрки до туза.
enum Rank { six, seven, eight, nine, ten, jack, queen, king, ace }

/// Неизменяемая игральная карта.
///
/// Равенство и хэш определяются только мастью и рангом ([faceUp]
/// не влияет), что удобно для игровых проверок.
class PlayingCard {
  final Suit suit;
  final Rank rank;
  final bool faceUp;

  const PlayingCard({
    required this.suit,
    required this.rank,
    this.faceUp = true,
  });

  PlayingCard copyWith({bool? faceUp}) {
    return PlayingCard(
      suit: suit,
      rank: rank,
      faceUp: faceUp ?? this.faceUp,
    );
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.clubs:
        return '♣';
      case Suit.diamonds:
        return '♦';
      case Suit.hearts:
        return '♥';
      case Suit.spades:
        return '♠';
    }
  }

  String get rankName {
    switch (rank) {
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  int get rankValue {
    return rank.index + 6;
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => '$rankName$suitSymbol';
}
