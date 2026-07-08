import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

typedef SavedStats = ({
  int gamesPlayed,
  int playerWins,
  int computerWins,
  int draws,
  int winStreak,
  int bestWinStreak,
});

class StatsService {
  static const _gamesPlayed = 'stats.gamesPlayed';
  static const _playerWins = 'stats.playerWins';
  static const _computerWins = 'stats.computerWins';
  static const _draws = 'stats.draws';
  static const _winStreak = 'stats.winStreak';
  static const _bestWinStreak = 'stats.bestWinStreak';

  Future<SavedStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      gamesPlayed: prefs.getInt(_gamesPlayed) ?? 0,
      playerWins: prefs.getInt(_playerWins) ?? 0,
      computerWins: prefs.getInt(_computerWins) ?? 0,
      draws: prefs.getInt(_draws) ?? 0,
      winStreak: prefs.getInt(_winStreak) ?? 0,
      bestWinStreak: prefs.getInt(_bestWinStreak) ?? 0,
    );
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_gamesPlayed, state.gamesPlayed),
      prefs.setInt(_playerWins, state.playerWins),
      prefs.setInt(_computerWins, state.computerWins),
      prefs.setInt(_draws, state.draws),
      prefs.setInt(_winStreak, state.winStreak),
      prefs.setInt(_bestWinStreak, state.bestWinStreak),
    ]);
  }
}
