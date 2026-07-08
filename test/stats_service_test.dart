import 'package:durak_game/models/game.dart';
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
    final state = GameState(
      gamesPlayed: 7,
      playerWins: 4,
      computerWins: 2,
      draws: 1,
      winStreak: 2,
      bestWinStreak: 3,
    );

    await service.save(state);
    final restored = await service.load();

    expect(restored.gamesPlayed, 7);
    expect(restored.playerWins, 4);
    expect(restored.computerWins, 2);
    expect(restored.draws, 1);
    expect(restored.winStreak, 2);
    expect(restored.bestWinStreak, 3);
  });
}
