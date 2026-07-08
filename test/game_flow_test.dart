import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/deck.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/player.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clubsSix = PlayingCard(suit: Suit.clubs, rank: Rank.six);
  const clubsSeven = PlayingCard(suit: Suit.clubs, rank: Rank.seven);
  const heartsSix = PlayingCard(suit: Suit.hearts, rank: Rank.six);
  const heartsSeven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);

  test('человек побеждает, когда сбрасывает последнюю карту в отбитом раунде',
      () {
    final state = GameState(
      deck: Deck.withCards([], trumpCard: heartsSeven),
      humanPlayer: Player(name: 'Игрок', type: PlayerType.human),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [clubsSix],
      ),
      tableCards: const [
        TableCard(attackCard: clubsSix, defenseCard: clubsSeven),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    final next = GameService().humanPass(state);

    expect(next.result, GameResult.playerWins);
    expect(next.phase, GamePhase.gameOver);
  });

  test(
      'компьютер забирает карты, когда не может отбить, и ход возвращается к человеку',
      () {
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [clubsSeven],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [
          heartsSix,
          const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      tableCards: const [TableCard(attackCard: clubsSeven)],
      phase: GamePhase.defending,
      isHumanTurn: false,
    );

    final taking = GameService().computerDefend(state);
    final next = GameService().humanFinishThrowIn(taking);

    // heartsSix не бьёт clubsSeven той же масти — компьютер забирает.
    expect(taking.phase, GamePhase.taking);
    expect(taking.isHumanTurn, isTrue);
    expect(next.tableCards, isEmpty);
    expect(next.computerPlayer.hand, containsAll([heartsSix, clubsSeven]));
    expect(next.phase, GamePhase.attacking);
    expect(next.isHumanTurn, isTrue);
  });

  test('после решения компьютера взять человек может докинуть карту', () {
    const heartsSeven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);
    final state = GameState(
      deck: Deck.withCards(const []),
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [heartsSeven],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [
          heartsSix,
          const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      tableCards: const [TableCard(attackCard: clubsSeven)],
      phase: GamePhase.defending,
      isHumanTurn: false,
    );
    final service = GameService();

    final taking = service.computerDefend(state);
    final thrownIn = service.humanThrowIn(taking, heartsSeven);
    final next = service.humanFinishThrowIn(thrownIn);

    expect(thrownIn.tableCards, hasLength(2));
    expect(
      next.computerPlayer.hand,
      containsAll([heartsSix, clubsSeven, heartsSeven]),
    );
    expect(next.tableCards, isEmpty);
  });

  test('компьютер докидывает подходящую карту человеку перед взятием', () {
    const diamondsSeven = PlayingCard(suit: Suit.diamonds, rank: Rank.seven);
    final state = GameState(
      deck: Deck.withCards(const []),
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [
          heartsSix,
          const PlayingCard(suit: Suit.spades, rank: Rank.ace),
        ],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [diamondsSeven],
      ),
      tableCards: const [TableCard(attackCard: clubsSeven)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
    final service = GameService();

    final taking = service.humanTakeCards(state);
    final thrownIn = service.computerThrowIn(taking);
    final next = service.computerThrowIn(thrownIn);

    expect(thrownIn.tableCards, hasLength(2));
    expect(
      next.humanPlayer.hand,
      containsAll([heartsSix, clubsSeven, diamondsSeven]),
    );
    expect(next.tableCards, isEmpty);
    expect(next.isHumanTurn, isFalse);
  });

  test('canHumanAddAttack запрещает подкидывать свыше лимита атак', () {
    final state = GameState(
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [clubsSix, heartsSix],
      ),
      computerPlayer: Player(
        name: 'Компьютер',
        type: PlayerType.computer,
        hand: [clubsSeven, heartsSeven],
      ),
      tableCards: List.generate(
        6,
        (_) => const TableCard(attackCard: clubsSix, defenseCard: heartsSeven),
      ),
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    expect(state.canHumanAddAttack, isFalse);
    expect(state.playableCards, isEmpty);
  });

  test('humanStarts: при равном младшем козыре ходит человек', () {
    final human = Player(
      name: 'Игрок',
      type: PlayerType.human,
      hand: [clubsSeven, heartsSix],
    );
    final computer = Player(
      name: 'Компьютер',
      type: PlayerType.computer,
      hand: [clubsSeven, heartsSix],
    );

    expect(GameService.humanStarts(human, computer, Suit.clubs), isTrue);
  });

  test('humanStarts: владелец младшего козыря ходит первым', () {
    final human = Player(
      name: 'Игрок',
      type: PlayerType.human,
      hand: [clubsSeven],
    );
    final computer = Player(
      name: 'Компьютер',
      type: PlayerType.computer,
      hand: [clubsSix],
    );

    expect(GameService.humanStarts(human, computer, Suit.clubs), isFalse);
  });

  test('humanStarts: без козырей у человека ходит компьютер', () {
    final human = Player(
      name: 'Игрок',
      type: PlayerType.human,
      hand: [heartsSix],
    );
    final computer = Player(
      name: 'Компьютер',
      type: PlayerType.computer,
      hand: [clubsSeven],
    );

    expect(GameService.humanStarts(human, computer, Suit.clubs), isFalse);
  });

  test('humanStarts: без козыря вообще ходит человек', () {
    final human =
        Player(name: 'Игрок', type: PlayerType.human, hand: [heartsSix]);
    final computer = Player(
      name: 'Компьютер',
      type: PlayerType.computer,
      hand: [heartsSeven],
    );

    expect(GameService.humanStarts(human, computer, null), isTrue);
  });

  test('козырная карта лежит под колодой и раздаётся последней', () {
    const trump = PlayingCard(suit: Suit.clubs, rank: Rank.ace);
    const filler = PlayingCard(suit: Suit.hearts, rank: Rank.six);
    // Козырь — последняя (нижняя) карта колоды; сверху — 12 обычных карт.
    final deck = Deck.withCards([
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      filler,
      trump,
    ]);
    final state = GameState(
      deck: deck,
      humanPlayer: Player(name: 'Игрок', type: PlayerType.human),
      computerPlayer: Player(name: 'Компьютер', type: PlayerType.computer),
      phase: GamePhase.waiting,
    );

    final started = GameService().startNewGame(state);

    expect(started.deck.trumpSuit, Suit.clubs);
    // После раздачи 12 карт козырь всё ещё в колоде.
    expect(started.deck.remainingCards, 1);
    expect(started.deck.trumpCard, trump);
  });

  group('защитные проверки GameService возвращают состояние без изменений', () {
    const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);
    const seven = PlayingCard(suit: Suit.clubs, rank: Rank.seven);
    const ace = PlayingCard(suit: Suit.spades, rank: Rank.ace);

    test('humanAttack игнорируется не в фазе атаки', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [six],
        ),
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      expect(GameService().humanAttack(state, six), same(state));
    });

    test('humanAttack игнорируется не в ход человека', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [six],
        ),
        phase: GamePhase.attacking,
        isHumanTurn: false,
      );
      expect(GameService().humanAttack(state, six), same(state));
    });

    test('humanAttack игнорируется, если карты нет в руке', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [seven],
        ),
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      expect(GameService().humanAttack(state, six), same(state));
    });

    test('humanAttack игнорируется при неподходящем ранге', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [ace, six],
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
      // ace — ранг туза, на столе только семёрка: подкинуть нельзя.
      expect(GameService().humanAttack(state, ace), same(state));
    });

    test('humanDefend игнорируется не в фазе защиты', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [seven],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      expect(GameService().humanDefend(state, seven), same(state));
    });

    test('humanDefend игнорируется, если карта не бьёт', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [six],
        ),
        tableCards: const [TableCard(attackCard: seven)],
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      expect(GameService().humanDefend(state, six), same(state));
    });

    test('humanDefend игнорируется, если атака уже отбита', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [ace],
        ),
        tableCards: const [
          TableCard(attackCard: six, defenseCard: seven),
        ],
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      expect(GameService().humanDefend(state, ace), same(state));
    });

    test('computerDefend игнорируется в фазе атаки', () {
      final state = GameState(
        computerPlayer: Player(
          name: 'Компьютер',
          type: PlayerType.computer,
          hand: [seven],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.attacking,
        isHumanTurn: false,
      );
      expect(GameService().computerDefend(state), same(state));
    });

    test('computerDefend игнорируется в ход человека', () {
      final state = GameState(
        computerPlayer: Player(
          name: 'Компьютер',
          type: PlayerType.computer,
          hand: [seven],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.defending,
        isHumanTurn: true,
      );
      expect(GameService().computerDefend(state), same(state));
    });

    test('humanTakeCards игнорируется не в фазе защиты', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [seven],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      expect(GameService().humanTakeCards(state), same(state));
    });

    test('humanPass игнорируется при пустом столе', () {
      final state = GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: [seven],
        ),
        phase: GamePhase.attacking,
        isHumanTurn: true,
      );
      expect(GameService().humanPass(state), same(state));
    });
  });

  test('компьютер побеждает, когда у человека остались карты', () {
    final state = GameState(
      deck: Deck.withCards(
        [],
        trumpCard: const PlayingCard(suit: Suit.hearts, rank: Rank.seven),
      ),
      humanPlayer: Player(
        name: 'Игрок',
        type: PlayerType.human,
        hand: [const PlayingCard(suit: Suit.clubs, rank: Rank.six)],
      ),
      computerPlayer: Player(name: 'Компьютер', type: PlayerType.computer),
      tableCards: const [
        TableCard(
          attackCard: PlayingCard(suit: Suit.clubs, rank: Rank.six),
          defenseCard: PlayingCard(suit: Suit.clubs, rank: Rank.seven),
        ),
      ],
      phase: GamePhase.attacking,
      isHumanTurn: true,
    );

    final next = GameService().humanPass(state);

    expect(next.result, GameResult.computerWins);
    expect(next.phase, GamePhase.gameOver);
  });
}
