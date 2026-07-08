import 'card.dart';
import 'dart:math';

/// Неизменяемая колода карт.
///
/// Любая операция (раздача, вытягивание, переворот козыря) возвращает новую
/// колоду, не мутируя текущую. Это позволяет безопасно использовать колоду
/// внутри неизменяемого [GameState].
class Deck {
  final List<PlayingCard> _cards;
  final PlayingCard? _trumpCard;

  /// Создаёт стандартную перетасованную колоду из 36 карт.
  factory Deck({Random? random}) {
    final cards = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    _shuffle(cards, random ?? Random());
    return Deck._(cards, null);
  }

  Deck._(List<PlayingCard> cards, this._trumpCard)
      : _cards = List<PlayingCard>.unmodifiable(cards);

  /// Создаёт колоду из готового списка карт и (опционально) козыря.
  factory Deck.withCards(
    List<PlayingCard> cards, {
    PlayingCard? trumpCard,
  }) =>
      Deck._(cards, trumpCard);

  static void _shuffle(List<PlayingCard> cards, Random random) {
    for (int i = cards.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = cards[i];
      cards[i] = cards[j];
      cards[j] = temp;
    }
  }

  /// Козырная карта (лежит под колодой лицом вверх) или null, если не задана.
  PlayingCard? get trumpCard => _trumpCard;

  /// Масть козыря.
  Suit? get trumpSuit => _trumpCard?.suit;

  /// Число оставшихся в колоде карт (включая козырь под колодой).
  int get remainingCards => _cards.length;

  /// Колода пуста.
  bool get isEmpty => _cards.isEmpty;

  /// Раздаёт до [count] карт с верха колоды.
  ///
  /// Возвращает новую колоду и список сданных карт.
  ({Deck deck, List<PlayingCard> dealt}) deal(int count) {
    final dealt = <PlayingCard>[];
    final newCards = List<PlayingCard>.of(_cards);
    for (int i = 0; i < count && newCards.isNotEmpty; i++) {
      dealt.add(newCards.removeLast());
    }
    return (
      deck: Deck._(newCards, _trumpCard),
      dealt: List<PlayingCard>.unmodifiable(dealt),
    );
  }

  /// Переворачивает нижнюю карту как козырь и кладёт её под колоду.
  Deck flipTrumpCard() {
    if (_cards.isEmpty) return this;
    final trump = _cards.last;
    final remaining = List<PlayingCard>.of(_cards.take(_cards.length - 1));
    remaining.insert(0, trump.copyWith(faceUp: true));
    return Deck._(remaining, trump);
  }

  /// Вытягивает верхнюю карту колоды.
  ///
  /// Возвращает новую колоду и вытянутую карту (или null, если колода пуста).
  ({Deck deck, PlayingCard? card}) drawCard() {
    if (_cards.isEmpty) return (deck: this, card: null);
    final card = _cards.last;
    return (
      deck: Deck._(_cards.take(_cards.length - 1).toList(), _trumpCard),
      card: card,
    );
  }
}
