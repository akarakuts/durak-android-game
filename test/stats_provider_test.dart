import 'dart:async';

import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/stats_state.dart';
import 'package:durak_game/providers/stats_provider.dart';
import 'package:durak_game/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStatsService extends StatsService {
  StatsState? lastSaved;

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
  Future<void> save(StatsState stats) async {
    lastSaved = stats;
  }
}

class _DelayedStatsService extends StatsService {
  final Completer<SavedStats> result = Completer<SavedStats>();
  final List<StatsState> saved = [];

  @override
  Future<SavedStats> load() => result.future;

  @override
  Future<void> save(StatsState stats) async => saved.add(stats);
}

void main() {
  test('победа увеличивает счётчик и обновляет серии', () {
    final notifier = StatsNotifier(_MemoryStatsService());

    notifier.recordResult(GameResult.playerWins);
    notifier.recordResult(GameResult.playerWins);

    expect(notifier.state.gamesPlayed, 2);
    expect(notifier.state.playerWins, 2);
    expect(notifier.state.winStreak, 2);
    expect(notifier.state.bestWinStreak, 2);
    notifier.dispose();
  });

  test('поражение сбрасывает текущую серию', () {
    final notifier = StatsNotifier(_MemoryStatsService());

    notifier.recordResult(GameResult.playerWins);
    notifier.recordResult(GameResult.computerWins);

    expect(notifier.state.winStreak, 0);
    expect(notifier.state.computerWins, 1);
    expect(notifier.state.bestWinStreak, 1);
    notifier.dispose();
  });

  test('ничья засчитывается и сбрасывает серию', () {
    final notifier = StatsNotifier(_MemoryStatsService());

    notifier.recordResult(GameResult.playerWins);
    notifier.recordResult(GameResult.draw);

    expect(notifier.state.draws, 1);
    expect(notifier.state.winStreak, 0);
    expect(notifier.state.bestWinStreak, 1);
    notifier.dispose();
  });

  test('нейтральный результат не меняет статистику', () {
    final notifier = StatsNotifier(_MemoryStatsService());

    notifier.recordResult(GameResult.none);

    expect(notifier.state.gamesPlayed, 0);
    notifier.dispose();
  });

  test('сброс обнуляет статистику', () async {
    final notifier = StatsNotifier(_MemoryStatsService());

    notifier.recordResult(GameResult.playerWins);
    await notifier.reset();

    expect(notifier.state.gamesPlayed, 0);
    notifier.dispose();
  });

  test('результат до окончания загрузки объединяется с сохранённым', () async {
    final service = _DelayedStatsService();
    final notifier = StatsNotifier(service);

    notifier.recordResult(GameResult.playerWins);
    service.result.complete(
      (
        gamesPlayed: 2,
        playerWins: 1,
        computerWins: 1,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 1,
      ),
    );
    await notifier.initialized;
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.gamesPlayed, 3);
    expect(notifier.state.playerWins, 2);
    expect(notifier.state.winStreak, 1);
    expect(service.saved.single.gamesPlayed, 3);
    notifier.dispose();
  });

  test('сброс во время загрузки не восстанавливает старые значения', () async {
    final service = _DelayedStatsService();
    final notifier = StatsNotifier(service);

    final reset = notifier.reset();
    service.result.complete(
      (
        gamesPlayed: 9,
        playerWins: 9,
        computerWins: 0,
        draws: 0,
        winStreak: 9,
        bestWinStreak: 9,
      ),
    );
    await reset;

    expect(notifier.state.gamesPlayed, 0);
    expect(service.saved.last.gamesPlayed, 0);
    notifier.dispose();
  });
}
