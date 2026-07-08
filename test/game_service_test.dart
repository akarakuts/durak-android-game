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
        hand: [const PlayingCard(suit: Suit.diamonds, rank: Rank.six)],
      ),
      tableCards: const [TableCard(attackCard: clubsSix)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
  }

  test('игрок может отбить старшей картой той же масти', () {
    final state = defendingState(humanCard: clubsSeven);

    final next = GameService().humanDefend(state, clubsSeven);

    expect(next.tableCards, isEmpty);
    expect(next.phase, GamePhase.attacking);
    expect(next.isHumanTurn, isTrue);
  });

  test('игрок не может отбить картой того же достоинства', () {
    final state = defendingState(humanCard: clubsSix);

    final next = GameService().humanDefend(state, clubsSix);

    expect(next, same(state));
    expect(next.tableCards.single.defenseCard, isNull);
    expect(next.humanPlayer.hand, contains(clubsSix));
    expect(next.phase, GamePhase.defending);
  });

  test('компьютер подкидывает карту подходящего достоинства', () {
    const heartsSeven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [
          clubsSeven,
          const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [heartsSeven],
      ),
      tableCards: const [TableCard(attackCard: clubsSix)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
    final service = GameService();

    final afterDefend = service.humanDefend(state, clubsSeven);
    final afterAttack = service.computerAttack(afterDefend);

    expect(afterAttack.tableCards, hasLength(2));
    expect(afterAttack.tableCards.last.attackCard, heartsSeven);
    expect(afterAttack.phase, GamePhase.defending);
    expect(afterAttack.isHumanTurn, isTrue);
  });

  test('пас завершает отбитый раунд и передаёт атаку компьютеру', () {
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [const PlayingCard(suit: Suit.diamonds, rank: Rank.six)],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [const PlayingCard(suit: Suit.spades, rank: Rank.ace)],
      ),
      tableCards: const [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    final next = GameService().humanPass(state);

    expect(next.tableCards, isEmpty);
    expect(next.phase, GamePhase.attacking);
    expect(next.isHumanTurn, isFalse);
  });

  test('одновременное завершение карт считается ничьей', () {
    var state = GameState(
      humanPlayer: Player(name: 'Игрок', type: PlayerType.human),
      computerPlayer: Player(name: 'Компьютер', type: PlayerType.computer),
      tableCards: const [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );
    var draw = state.deck.drawCard();
    while (draw.card != null) {
      state = state.copyWith(deck: draw.deck);
      draw = state.deck.drawCard();
    }

    final next = GameService().humanPass(state);

    expect(next.result, GameResult.draw);
    expect(next.phase, GamePhase.gameOver);
  });

  test('после отбоя атакующий добирает первым', () {
    const humanDraw = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
    const computerDraw = PlayingCard(suit: Suit.spades, rank: Rank.ace);
    final state = GameState(
      deck: Deck.withCards([computerDraw, humanDraw]),
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [const PlayingCard(suit: Suit.hearts, rank: Rank.six)],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [const PlayingCard(suit: Suit.spades, rank: Rank.six)],
      ),
      tableCards: const [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    final next = GameService().humanPass(state);

    expect(next.humanPlayer.hand, contains(humanDraw));
    expect(next.computerPlayer.hand, contains(computerDraw));
  });

  test('операции не мутируют исходное состояние', () {
    final original = defendingState(humanCard: clubsSeven);

    final defended = GameService().humanDefend(original, clubsSeven);

    // Исходное состояние сохранено.
    expect(original.humanPlayer.hand, contains(clubsSeven));
    expect(original.tableCards.single.defenseCard, isNull);
    expect(original.phase, GamePhase.defending);
    // Результат операции — раунд завершён, стол очищен, ход остался за
    // человеком (он отбил единственную атаку).
    expect(defended.tableCards, isEmpty);
    expect(defended.phase, GamePhase.attacking);
    expect(defended.isHumanTurn, isTrue);
  });
}
