import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/deck.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/player.dart';
import 'package:durak_game/models/stats_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayingCard', () {
    test('copyWith меняет только faceUp', () {
      const card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(card.faceUp, isTrue);
      expect(card.copyWith(faceUp: false).faceUp, isFalse);
      expect(card.copyWith().faceUp, isTrue);
    });

    test('suitSymbol и rankName覆盖 все масти и ранги', () {
      const c = PlayingCard(suit: Suit.clubs, rank: Rank.jack);
      const d = PlayingCard(suit: Suit.diamonds, rank: Rank.queen);
      const h = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      const s = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      expect([c, d, h, s].map((e) => e.suitSymbol), ['♣', '♦', '♥', '♠']);

      final ranks = [
        Rank.six,
        Rank.seven,
        Rank.eight,
        Rank.nine,
        Rank.ten,
        Rank.jack,
        Rank.queen,
        Rank.king,
        Rank.ace,
      ];
      const card = PlayingCard(suit: Suit.clubs, rank: Rank.six);
      final names = ranks
          .map((r) => PlayingCard(suit: Suit.clubs, rank: r).rankName)
          .toList();
      expect(names, ['6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']);
      expect(card.rankValue, 6);
      expect(card.isRed, isFalse);
      expect(
        const PlayingCard(suit: Suit.hearts, rank: Rank.six).isRed,
        isTrue,
      );
    });

    test('равенство и hashCode по масти и рангу', () {
      const a = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      const b = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      const other = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == other, isFalse);
      expect(a == Object(), isFalse);
    });

    test('toString возвращает ранг и масть', () {
      const card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(card.toString(), 'A♥');
    });
  });

  group('TableCard', () {
    test('copyWith заменяет поля', () {
      const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);
      const seven = PlayingCard(suit: Suit.clubs, rank: Rank.seven);
      const tc = TableCard(attackCard: six);
      expect(tc.isDefended, isFalse);
      final defended = tc.copyWith(defenseCard: seven);
      expect(defended.isDefended, isTrue);
      expect(defended.attackCard, six);
      expect(tc.copyWith(attackCard: seven).attackCard, seven);
      expect(tc.copyWith(defenseCard: null).defenseCard, isNull);
    });
  });

  group('Неизменяемые коллекции', () {
    test('Player защищён от изменения исходного списка и публичной руки', () {
      final source = <PlayingCard>[
        const PlayingCard(suit: Suit.clubs, rank: Rank.six),
      ];
      final player = Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: source,
      );

      source.clear();

      expect(player.hand, hasLength(1));
      expect(() => player.hand.clear(), throwsUnsupportedError);
    });

    test('Deck копирует переданный список', () {
      final source = <PlayingCard>[
        const PlayingCard(suit: Suit.clubs, rank: Rank.six),
      ];
      final deck = Deck.withCards(source);

      source.clear();

      expect(deck.remainingCards, 1);
    });

    test('GameState защищает список карт на столе', () {
      final table = <TableCard>[
        const TableCard(
          attackCard: PlayingCard(suit: Suit.clubs, rank: Rank.six),
        ),
      ];
      final state = GameState(tableCards: table);

      table.clear();

      expect(state.tableCards, hasLength(1));
      expect(() => state.tableCards.clear(), throwsUnsupportedError);
    });
  });

  group('GameState getters', () {
    test('canPass только в фазе атаки и с непустым столом', () {
      const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);
      final attacking = GameState(
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      final defending = GameState(
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      final empty = GameState(phase: GamePhase.attacking, isHumanTurn: true);
      expect(attacking.canPass, isTrue);
      expect(defending.canPass, isFalse);
      expect(empty.canPass, isFalse);
      expect(empty.isTableEmpty, isTrue);
    });

    test('playableCards фильтрует атаку по рангам на столе', () {
      const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);
      const seven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);
      const ace = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [six, seven, ace],
        ),
        computerPlayer: Player(
          name: 'Компьютер',
          type: PlayerType.computer,
          hand: [six, six, six, six, six, six],
        ),
        tableCards: const [TableCard(attackCard: seven)],
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      // Подкидывать можно только карту ранга, уже есть на столе (семёрка).
      expect(state.playableCards, [seven]);
    });

    test('playableCards для защиты возвращает бьющие карты', () {
      const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);
      const seven = PlayingCard(suit: Suit.clubs, rank: Rank.seven);
      const ace = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [ace, seven],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      // ace (пики) не бьёт six (трефы); seven (трефы старше) бьёт.
      expect(state.playableCards, [seven]);
    });

    test('playableCards пуст, когда не ход человека', () {
      final state = GameState(phase: GamePhase.attacking, isHumanTurn: false);
      expect(state.playableCards, isEmpty);
    });
  });

  group('StatsState', () {
    test('copyWith заменяет поля', () {
      const s = StatsState(gamesPlayed: 1);
      final next = s.copyWith(playerWins: 1, winStreak: 1);
      expect(next.gamesPlayed, 1);
      expect(next.playerWins, 1);
      expect(next.winStreak, 1);
    });

    test('winRate считает процент побед', () {
      expect(const StatsState().winRate, 0);
      expect(const StatsState(gamesPlayed: 4, playerWins: 3).winRate, 75.0);
    });
  });
}
