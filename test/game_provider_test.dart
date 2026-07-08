import 'package:durak_game/models/game.dart';
import 'package:durak_game/providers/game_provider.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:durak_game/services/stats_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingGameService extends GameService {
  int computerAttacks = 0;

  @override
  void startNewGame(GameState state) {
    state.phase = GamePhase.attacking;
    state.isHumanTurn = false;
    state.result = GameResult.none;
  }

  @override
  void computerAttack(GameState state) {
    computerAttacks++;
    state.isHumanTurn = true;
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
  Future<void> save(GameState state) async {}
}

void main() {
  test('новая игра отменяет устаревший таймер компьютера', () {
    fakeAsync((async) {
      final gameService = _CountingGameService();
      final notifier = GameStateNotifier(gameService, _MemoryStatsService());

      notifier.startNewGame();
      notifier.startNewGame();
      async.elapse(const Duration(milliseconds: 500));

      expect(gameService.computerAttacks, 1);
      notifier.dispose();
    });
  });
}
