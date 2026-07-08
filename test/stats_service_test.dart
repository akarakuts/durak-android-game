import 'package:durak_game/models/stats_state.dart';
import 'package:durak_game/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('статистика сохраняется и восстанавливается полностью', () async {
    final service = StatsService();
    const stats = StatsState(
      gamesPlayed: 7,
      playerWins: 4,
      computerWins: 2,
      draws: 1,
      winStreak: 2,
      bestWinStreak: 3,
    );

    await service.save(stats);
    final restored = await service.load();

    expect(restored.gamesPlayed, 7);
    expect(restored.playerWins, 4);
    expect(restored.computerWins, 2);
    expect(restored.draws, 1);
    expect(restored.winStreak, 2);
    expect(restored.bestWinStreak, 3);
  });

  test('старые раздельные ключи мигрируют при отсутствии снимка', () async {
    SharedPreferences.setMockInitialValues({
      'stats.gamesPlayed': 4,
      'stats.playerWins': 2,
      'stats.computerWins': 1,
      'stats.draws': 1,
      'stats.winStreak': 1,
      'stats.bestWinStreak': 2,
    });

    final restored = await StatsService().load();

    expect(restored.gamesPlayed, 4);
    expect(restored.playerWins, 2);
    expect(restored.computerWins, 1);
    expect(restored.draws, 1);
    expect(restored.winStreak, 1);
    expect(restored.bestWinStreak, 2);
  });

  test('повреждённый снимок не блокирует чтение старых ключей', () async {
    SharedPreferences.setMockInitialValues({
      'stats.snapshot.v1': '{broken',
      'stats.gamesPlayed': 3,
    });

    final restored = await StatsService().load();

    expect(restored.gamesPlayed, 3);
  });

  test('некорректные и отрицательные значения снимка заменяются нулями',
      () async {
    SharedPreferences.setMockInitialValues({
      'stats.snapshot.v1':
          '{"gamesPlayed":-2,"playerWins":"x","computerWins":1}',
    });

    final restored = await StatsService().load();

    expect(restored.gamesPlayed, 0);
    expect(restored.playerWins, 0);
    expect(restored.computerWins, 1);
  });
}
