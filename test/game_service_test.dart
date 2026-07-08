import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/deck.dart';
import 'package:durak_game/models/player.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clubsSix = PlayingCard(suit: Suit.clubs, rank: Rank.six);
  const clubsSeven = PlayingCard(suit: Suit.clubs, rank: Rank.seven);

  GameState defendingState({required PlayingCard humanCard}) {
    return GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [humanCard],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: const [PlayingCard(suit: Suit.diamonds, rank: Rank.six)],
      ),
      tableCards: [TableCard(attackCard: clubsSix)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
  }

  test('игрок может отбить старшей картой той же масти', () {
    final state = defendingState(humanCard: clubsSeven);

    GameService().humanDefend(state, clubsSeven);

    expect(state.tableCards, isEmpty);
    expect(state.phase, GamePhase.attacking);
    expect(state.isHumanTurn, isTrue);
  });

  test('игрок не может отбить картой того же достоинства', () {
    final state = defendingState(humanCard: clubsSix);

    GameService().humanDefend(state, clubsSix);

    expect(state.tableCards.single.defenseCard, isNull);
    expect(state.humanPlayer.hand, contains(clubsSix));
    expect(state.phase, GamePhase.defending);
  });

  test('компьютер подкидывает карту подходящего достоинства', () {
    const heartsSeven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: const [
          clubsSeven,
          PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: const [heartsSeven],
      ),
      tableCards: [TableCard(attackCard: clubsSix)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
    final service = GameService();

    service.humanDefend(state, clubsSeven);
    service.computerAttack(state);

    expect(state.tableCards, hasLength(2));
    expect(state.tableCards.last.attackCard, heartsSeven);
    expect(state.phase, GamePhase.defending);
    expect(state.isHumanTurn, isTrue);
  });

  test('пас завершает отбитый раунд и передаёт атаку компьютеру', () {
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: const [PlayingCard(suit: Suit.diamonds, rank: Rank.six)],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: const [PlayingCard(suit: Suit.spades, rank: Rank.ace)],
      ),
      tableCards: [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    GameService().humanPass(state);

    expect(state.tableCards, isEmpty);
    expect(state.phase, GamePhase.attacking);
    expect(state.isHumanTurn, isFalse);
  });

  test('одновременное завершение карт считается ничьей', () {
    final state = GameState(
      humanPlayer: Player(name: 'Игрок', type: PlayerType.human),
      computerPlayer: Player(name: 'Компьютер', type: PlayerType.computer),
      tableCards: [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );
    while (state.deck.drawCard() != null) {}

    GameService().humanPass(state);

    expect(state.result, GameResult.draw);
    expect(state.phase, GamePhase.gameOver);
    expect(state.gamesPlayed, 1);
    expect(state.draws, 1);
  });

  test('после отбоя атакующий добирает первым', () {
    const humanDraw = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
    const computerDraw = PlayingCard(suit: Suit.spades, rank: Rank.ace);
    final state = GameState(
      deck: Deck.withCards([computerDraw, humanDraw]),
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.six)],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: const [PlayingCard(suit: Suit.spades, rank: Rank.six)],
      ),
      tableCards: [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    GameService().humanPass(state);

    expect(state.humanPlayer.hand, contains(humanDraw));
    expect(state.computerPlayer.hand, contains(computerDraw));
  });

  test('копия состояния не разделяет изменяемые коллекции', () {
    final original = defendingState(humanCard: clubsSeven);
    final copy = GameState.copy(original);

    copy.humanPlayer.removeCard(clubsSeven);
    copy.tableCards.single.defenseCard = clubsSeven;
    copy.deck.drawCard();

    expect(original.humanPlayer.hand, contains(clubsSeven));
    expect(original.tableCards.single.defenseCard, isNull);
    expect(copy.deck.remainingCards, original.deck.remainingCards - 1);
  });
}
