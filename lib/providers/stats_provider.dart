import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import '../models/game.dart';
import '../models/stats_state.dart';
import '../services/stats_service.dart';

/// Провайдер [StatsService] (доступ к SharedPreferences).
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

/// Накопленная статистика партий.
final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref.read(statsServiceProvider));
});

/// Хранит и обновляет статистику партий, персистентно сохраняя её.
class StatsNotifier extends StateNotifier<StatsState> {
  final StatsService _service;
  final Completer<void> _initialized = Completer<void>();
  final List<GameResult> _pendingResults = [];
  Future<void> _saveTail = Future<void>.value();
  bool _loaded = false;
  bool _resetRequested = false;

  StatsNotifier(this._service) : super(const StatsState()) {
    unawaited(_load());
  }

  /// Завершается, когда сохранённый снимок загружен и объединён с локальными
  /// результатами, пришедшими во время холодного старта.
  Future<void> get initialized => _initialized.future;

  Future<void> _load() async {
    var loaded = const StatsState();
    try {
      final saved = await _service.load();
      loaded = StatsState(
        gamesPlayed: saved.gamesPlayed,
        playerWins: saved.playerWins,
        computerWins: saved.computerWins,
        draws: saved.draws,
        winStreak: saved.winStreak,
        bestWinStreak: saved.bestWinStreak,
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Не удалось загрузить статистику',
        name: 'durak.stats',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (mounted) {
      if (_resetRequested) {
        state = const StatsState();
      } else {
        for (final result in _pendingResults) {
          loaded = _applyResult(loaded, result);
        }
        state = loaded;
      }
      final shouldPersist = _resetRequested || _pendingResults.isNotEmpty;
      _pendingResults.clear();
      _loaded = true;
      if (shouldPersist) _enqueueSave(state);
    }
    if (!_initialized.isCompleted) _initialized.complete();
  }

  /// Записывает результат завершённой партии.
  void recordResult(GameResult result) {
    if (result == GameResult.none) return;
    state = _applyResult(state, result);
    if (!_loaded) {
      if (!_resetRequested) _pendingResults.add(result);
      return;
    }
    _enqueueSave(state);
  }

  StatsState _applyResult(StatsState current, GameResult result) {
    switch (result) {
      case GameResult.playerWins:
        final winStreak = current.winStreak + 1;
        return current.copyWith(
          gamesPlayed: current.gamesPlayed + 1,
          playerWins: current.playerWins + 1,
          winStreak: winStreak,
          bestWinStreak: winStreak > current.bestWinStreak
              ? winStreak
              : current.bestWinStreak,
        );
      case GameResult.computerWins:
        return current.copyWith(
          gamesPlayed: current.gamesPlayed + 1,
          computerWins: current.computerWins + 1,
          winStreak: 0,
        );
      case GameResult.draw:
        return current.copyWith(
          gamesPlayed: current.gamesPlayed + 1,
          draws: current.draws + 1,
          winStreak: 0,
        );
      case GameResult.none:
        return current;
    }
  }

  /// Сбрасывает статистику к нулю.
  Future<void> reset() async {
    state = const StatsState();
    _pendingResults.clear();
    if (!_loaded) {
      _resetRequested = true;
      await initialized;
    } else {
      _enqueueSave(state);
    }
    await _saveTail;
  }

  void _enqueueSave(StatsState snapshot) {
    _saveTail = _saveTail.then((_) => _service.save(snapshot)).catchError(
      (Object error, StackTrace stackTrace) {
        developer.log(
          'Не удалось сохранить статистику',
          name: 'durak.stats',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
