import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../services/stats_service.dart';

final gameServiceProvider = Provider<GameService>((ref) => GameService());
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier(
    ref.read(gameServiceProvider),
    ref.read(statsServiceProvider),
  );
});

class GameStateNotifier extends StateNotifier<GameState> {
  final GameService _gameService;
  final StatsService _statsService;
  Timer? _pendingComputerAction;
  int _gameGeneration = 0;
  int _lastSavedGames = 0;
  bool _statsLoaded = false;

  GameStateNotifier(this._gameService, this._statsService)
      : super(GameState()) {
    startNewGame();
    _restoreStats();
  }

  void startNewGame() {
    _pendingComputerAction?.cancel();
    _gameGeneration++;
    final next = GameState(
      gamesPlayed: state.gamesPlayed,
      playerWins: state.playerWins,
      computerWins: state.computerWins,
      draws: state.draws,
      winStreak: state.winStreak,
      bestWinStreak: state.bestWinStreak,
    );
    _gameService.startNewGame(next);
    state = next;

    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn, delay: 500);
    }
  }

  void humanAttack(PlayingCard card) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    _apply((next) => _gameService.humanAttack(next, card));

    if (state.result != GameResult.none) return;

    _scheduleComputerAction(_computerDefend);
  }

  void humanDefend(PlayingCard card) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;
    _apply((next) => _gameService.humanDefend(next, card));

    if (state.result != GameResult.none) return;

    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  void humanTakeCards() {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;
    _apply(_gameService.humanTakeCards);

    if (state.result != GameResult.none) return;

    _scheduleComputerAction(_computerTurn);
  }

  void humanPass() {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    _apply(_gameService.humanPass);

    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  void _computerTurn() {
    if (state.result != GameResult.none) return;

    if (state.isHumanTurn) return;

    if (state.tableCards.isEmpty ||
        state.tableCards.every((tc) => tc.isDefended)) {
      _apply(_gameService.computerAttack);
    } else {
      _apply(_gameService.computerDefend);
    }

    if (state.result != GameResult.none) return;

    if (state.isHumanTurn && state.phase == GamePhase.attacking) {
      // Human's turn to attack
    }
  }

  void _computerDefend() {
    if (state.result != GameResult.none) return;
    if (state.isHumanTurn) return;

    _apply(_gameService.computerDefend);

    if (state.result != GameResult.none) return;

    if (state.isHumanTurn && state.phase == GamePhase.attacking) {
      // Human attacks again after successful defense
    } else if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  void _apply(void Function(GameState) action) {
    final next = GameState.copy(state);
    action(next);
    state = next;
    if (_statsLoaded && state.gamesPlayed != _lastSavedGames) {
      _lastSavedGames = state.gamesPlayed;
      _saveStats();
    }
  }

  void _scheduleComputerAction(
    void Function() action, {
    int delay = 800,
  }) {
    _pendingComputerAction?.cancel();
    final generation = _gameGeneration;
    _pendingComputerAction = Timer(Duration(milliseconds: delay), () {
      if (generation == _gameGeneration && mounted) action();
    });
  }

  Future<void> _restoreStats() async {
    SavedStats stats;
    try {
      stats = await _statsService.load();
    } catch (_) {
      _statsLoaded = true;
      return;
    }
    if (!mounted) return;
    final next = GameState.copy(state)
      ..gamesPlayed += stats.gamesPlayed
      ..playerWins += stats.playerWins
      ..computerWins += stats.computerWins
      ..draws += stats.draws
      ..winStreak = state.gamesPlayed == 0 ? stats.winStreak : state.winStreak
      ..bestWinStreak = state.bestWinStreak > stats.bestWinStreak
          ? state.bestWinStreak
          : stats.bestWinStreak;
    state = next;
    _statsLoaded = true;
    _lastSavedGames = state.gamesPlayed;
    if (state.gamesPlayed > stats.gamesPlayed) {
      _saveStats();
    }
  }

  void _saveStats() {
    unawaited(_statsService.save(state).catchError((_) {}));
  }

  @override
  void dispose() {
    _pendingComputerAction?.cancel();
    super.dispose();
  }
}
