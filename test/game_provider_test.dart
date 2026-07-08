import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/player.dart';
import 'package:durak_game/models/stats_state.dart';
import 'package:durak_game/providers/game_provider.dart';
import 'package:durak_game/providers/stats_provider.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:durak_game/services/stats_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingGameService extends GameService {
  int computerAttacks = 0;

  @override
  GameState startNewGame(GameState state) {
    return state.copyWith(
      phase: GamePhase.attacking,
      isHumanTurn: false,
      result: GameResult.none,
    );
  }

  @override
  GameState computerAttack(GameState state) {
    computerAttacks++;
    return state.copyWith(isHumanTurn: true);
  }
}

class _FlowGameService extends GameService {
  _FlowGameService(this.initial);

  final GameState initial;
  int computerAttacks = 0;
  int computerDefenses = 0;
  int computerThrowIns = 0;
  int humanThrowIns = 0;
  int humanFinishes = 0;

  GameState Function(GameState, PlayingCard)? onHumanAttack;
  GameState Function(GameState, PlayingCard)? onHumanDefend;
  GameState Function(GameState)? onHumanTake;
  GameState Function(GameState)? onHumanPass;
  GameState Function(GameState)? onComputerAttack;
  GameState Function(GameState)? onComputerDefend;
  GameState Function(GameState)? onComputerThrowIn;

  @override
  GameState startNewGame(GameState state) => initial;

  @override
  GameState humanAttack(GameState state, PlayingCard card) =>
      onHumanAttack?.call(state, card) ?? state;

  @override
  GameState humanDefend(GameState state, PlayingCard card) =>
      onHumanDefend?.call(state, card) ?? state;

  @override
  GameState humanTakeCards(GameState state) =>
      onHumanTake?.call(state) ?? state;

  @override
  GameState humanPass(GameState state) => onHumanPass?.call(state) ?? state;

  @override
  GameState humanThrowIn(GameState state, PlayingCard card) {
    humanThrowIns++;
    return state;
  }

  @override
  GameState humanFinishThrowIn(GameState state) {
    humanFinishes++;
    return state;
  }

  @override
  GameState computerAttack(GameState state) {
    computerAttacks++;
    return onComputerAttack?.call(state) ?? state;
  }

  @override
  GameState computerDefend(GameState state) {
    computerDefenses++;
    return onComputerDefend?.call(state) ?? state;
  }

  @override
  GameState computerThrowIn(GameState state) {
    computerThrowIns++;
    return onComputerThrowIn?.call(state) ?? state;
  }
}

class _MemoryStatsService extends StatsService {
  @override
  Future<SavedStats> load() async => (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      );

  @override
  Future<void> save(StatsState stats) async {}
}

void main() {
  const six = PlayingCard(suit: Suit.clubs, rank: Rank.six);

  test('новая игра отменяет устаревший таймер компьютера', () {
    fakeAsync((async) {
      final gameService = _CountingGameService();
      final statsNotifier = StatsNotifier(_MemoryStatsService());
      final notifier = GameStateNotifier(gameService, statsNotifier);

      expect(notifier.state.phase, GamePhase.waiting);
      notifier.startNewGame();
      notifier.startNewGame();
      async.elapse(const Duration(milliseconds: 500));

      expect(gameService.computerAttacks, 1);
      notifier.dispose();
      statsNotifier.dispose();
    });
  });

  test('атака человека запускает отложенную защиту компьютера', () {
    fakeAsync((async) {
      final service = _FlowGameService(
        GameState(
          humanPlayer: Player(
            name: 'Игрок',
            type: PlayerType.human,
            hand: const [six],
          ),
          phase: GamePhase.attacking,
          isHumanTurn: true,
        ),
      );
      service.onHumanAttack = (state, card) => state.copyWith(
            phase: GamePhase.defending,
            isHumanTurn: false,
            tableCards: const [TableCard(attackCard: six)],
          );
      service.onComputerDefend = (state) => state.copyWith(
            phase: GamePhase.attacking,
            isHumanTurn: true,
          );
      final stats = StatsNotifier(_MemoryStatsService());
      final notifier = GameStateNotifier(service, stats);
      notifier.startNewGame();

      notifier.humanAttack(six);
      async.elapse(const Duration(milliseconds: 800));

      expect(service.computerDefenses, 1);
      expect(notifier.state.isHumanTurn, isTrue);
      notifier.dispose();
      stats.dispose();
    });
  });

  test('защита человека передаёт компьютеру следующую атаку', () {
    fakeAsync((async) {
      final service = _FlowGameService(
        GameState(
          humanPlayer: Player(
            name: 'Игрок',
            type: PlayerType.human,
            hand: const [six],
          ),
          tableCards: const [TableCard(attackCard: six)],
          phase: GamePhase.defending,
          isHumanTurn: true,
        ),
      );
      service.onHumanDefend = (state, card) => state.copyWith(
            phase: GamePhase.attacking,
            isHumanTurn: false,
            tableCards: const [],
          );
      service.onComputerAttack = (state) => state.copyWith(isHumanTurn: true);
      final stats = StatsNotifier(_MemoryStatsService());
      final notifier = GameStateNotifier(service, stats);
      notifier.startNewGame();

      notifier.humanDefend(six);
      async.elapse(const Duration(milliseconds: 800));

      expect(service.computerAttacks, 1);
      notifier.dispose();
      stats.dispose();
    });
  });

  test('взятие человеком запускает докидывание и следующий ход компьютера', () {
    fakeAsync((async) {
      final service = _FlowGameService(
        GameState(
          tableCards: const [TableCard(attackCard: six)],
          phase: GamePhase.defending,
          isHumanTurn: true,
        ),
      );
      service.onHumanTake = (state) => state.copyWith(
            phase: GamePhase.taking,
            isHumanTurn: false,
          );
      service.onComputerThrowIn = (state) => state.copyWith(
            phase: GamePhase.attacking,
            isHumanTurn: false,
            tableCards: const [],
          );
      service.onComputerAttack = (state) => state.copyWith(isHumanTurn: true);
      final stats = StatsNotifier(_MemoryStatsService());
      final notifier = GameStateNotifier(service, stats);
      notifier.startNewGame();

      notifier.humanTakeCards();
      async.elapse(const Duration(milliseconds: 1600));

      expect(service.computerThrowIns, 1);
      expect(service.computerAttacks, 1);
      notifier.dispose();
      stats.dispose();
    });
  });

  test('человек может докинуть и завершить взятие компьютера', () {
    final service = _FlowGameService(
      GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: const [six],
        ),
        computerPlayer: Player(
          name: 'Компьютер',
          type: PlayerType.computer,
          hand: const [six, six],
        ),
        tableCards: const [TableCard(attackCard: six)],
        phase: GamePhase.taking,
        isHumanTurn: true,
      ),
    );
    final stats = StatsNotifier(_MemoryStatsService());
    final notifier = GameStateNotifier(service, stats);
    notifier.startNewGame();

    notifier.humanThrowIn(six);
    notifier.humanFinishThrowIn();

    expect(service.humanThrowIns, 1);
    expect(service.humanFinishes, 1);
    notifier.dispose();
    stats.dispose();
  });

  test('завершение партии записывает результат в статистику', () async {
    final service = _FlowGameService(
      GameState(
        humanPlayer: Player(
          name: 'Игрок',
          type: PlayerType.human,
          hand: const [six],
        ),
        phase: GamePhase.attacking,
        isHumanTurn: true,
      ),
    );
    service.onHumanAttack = (state, card) => state.copyWith(
          phase: GamePhase.gameOver,
          result: GameResult.playerWins,
        );
    final stats = StatsNotifier(_MemoryStatsService());
    await stats.initialized;
    final notifier = GameStateNotifier(service, stats);
    notifier.startNewGame();

    notifier.humanAttack(six);

    expect(stats.state.playerWins, 1);
    notifier.dispose();
    stats.dispose();
  });
}
