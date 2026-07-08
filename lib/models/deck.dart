import 'card.dart';
import 'dart:math';

class Deck {
  List<PlayingCard> _cards = [];
  PlayingCard? _trumpCard;

  Deck({Random? random}) {
    _initialize(random ?? Random());
  }

  Deck.copy(Deck other)
      : _cards = List<PlayingCard>.of(other._cards),
        _trumpCard = other._trumpCard;

  Deck.withCards(
    List<PlayingCard> cards, {
    PlayingCard? trumpCard,
  })  : _cards = List<PlayingCard>.of(cards),
        _trumpCard = trumpCard;

  void _initialize(Random random) {
    _cards = [];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        _cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    _shuffle(random);
  }

  void _shuffle(Random random) {
    for (int i = _cards.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  PlayingCard? get trumpCard => _trumpCard;

  Suit? get trumpSuit => _trumpCard?.suit;

  int get remainingCards => _cards.length;

  List<PlayingCard> deal(int count) {
    final dealt = <PlayingCard>[];
    for (int i = 0; i < count && _cards.isNotEmpty; i++) {
      dealt.add(_cards.removeLast());
    }
    return dealt;
  }

  void flipTrumpCard() {
    if (_cards.isNotEmpty) {
      _trumpCard = _cards.removeLast();
      _cards.insert(0, _trumpCard!.copyWith(faceUp: true));
    }
  }

  bool get isEmpty => _cards.isEmpty;

  PlayingCard? drawCard() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }
}
