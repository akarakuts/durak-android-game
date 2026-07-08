import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import '../models/card.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import 'stats_provider.dart';
import '../utils/game_rules.dart';

/// Провайдер [GameService] с правилами игры.
final gameServiceProvider = Provider<GameService>((ref) => GameService());

/// Текущее состояние партии и нотифаер, управляющий ходами.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier(
    ref.read(gameServiceProvider),
    ref.read(statsNotifierProvider.notifier),
  );
});

/// Управляет жизненным циклом партии и связывает [GameService] с Riverpod.
///
/// Статистику партий ведёт отдельный [StatsNotifier]; этот нотифаер лишь
/// сообщает ему о завершении партии.
class GameStateNotifier extends StateNotifier<GameState> {
  final GameService _gameService;
  final StatsNotifier _statsNotifier;
  Timer? _pendingComputerAction;
  int _gameGeneration = 0;

  GameStateNotifier(this._gameService, this._statsNotifier)
      : super(GameState());

  /// Начинает новую партию.
  void startNewGame() {
    _pendingComputerAction?.cancel();
    _gameGeneration++;
    state = _gameService.startNewGame(GameState());

    if (!state.isHumanTurn) {
      _scheduleComputerAction(
        _computerTurn,
        delay: GameRules.computerFirstMoveDelayMs,
      );
    }
  }

  /// Ход человека в атаке.
  void humanAttack(PlayingCard card) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    _apply((s) => _gameService.humanAttack(s, card));

    if (state.result != GameResult.none) return;

    _scheduleComputerAction(_computerDefend);
  }

  /// Ход человека в защите.
  void humanDefend(PlayingCard card) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;
    _apply((s) => _gameService.humanDefend(s, card));

    if (state.result != GameResult.none) return;

    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  /// Человек забирает карты со стола.
  void humanTakeCards() {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;
    _apply(_gameService.humanTakeCards);

    if (state.result != GameResult.none) return;

    _scheduleComputerAction(_computerTurn);
  }

  /// Докидывает карту компьютеру, который решил забрать стол.
  void humanThrowIn(PlayingCard card) {
    if (!state.canHumanFinishThrowIn) return;
    _apply((s) => _gameService.humanThrowIn(s, card));
  }

  /// Завершает докидывание и начинает следующий раунд.
  void humanFinishThrowIn() {
    if (!state.canHumanFinishThrowIn) return;
    _apply(_gameService.humanFinishThrowIn);
  }

  /// Человек пасует.
  void humanPass() {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    _apply(_gameService.humanPass);

    if (state.result != GameResult.none) return;

    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  /// Один шаг хода компьютера (атака или защита — по ситуации).
  void _computerTurn() {
    if (state.result != GameResult.none) return;
    if (state.isHumanTurn) return;

    if (state.phase == GamePhase.taking) {
      _apply(_gameService.computerThrowIn);
      if (state.result == GameResult.none && !state.isHumanTurn) {
        _scheduleComputerAction(_computerTurn);
      }
    } else if (state.tableCards.isEmpty ||
        state.tableCards.every((tc) => tc.isDefended)) {
      _apply(_gameService.computerAttack);
    } else {
      _apply(_gameService.computerDefend);
    }
  }

  /// Шаг защиты компьютера после атаки человека.
  void _computerDefend() {
    if (state.result != GameResult.none) return;
    if (state.isHumanTurn) return;

    _apply(_gameService.computerDefend);

    if (state.result != GameResult.none) return;

    if (state.isHumanTurn && state.phase == GamePhase.attacking) {
      // Атака снова переходит к человеку после успешного отбоя.
      return;
    }
    if (!state.isHumanTurn) {
      _scheduleComputerAction(_computerTurn);
    }
  }

  /// Применяет к состоянию чистую функцию [action] и фиксирует итог партии.
  void _apply(GameState Function(GameState) action) {
    final previous = state;
    state = action(state);
    if (state.result != GameResult.none && previous.result == GameResult.none) {
      _statsNotifier.recordResult(state.result);
    }
  }

  void _scheduleComputerAction(
    void Function() action, {
    int delay = GameRules.computerActionDelayMs,
  }) {
    _pendingComputerAction?.cancel();
    final generation = _gameGeneration;
    _pendingComputerAction = Timer(Duration(milliseconds: delay), () {
      if (generation == _gameGeneration && mounted) action();
    });
  }

  @override
  void dispose() {
    _pendingComputerAction?.cancel();
    super.dispose();
  }
}
