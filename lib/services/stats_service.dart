import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats_state.dart';

/// Снимок сохранённой статистики.
typedef SavedStats = ({
  int gamesPlayed,
  int playerWins,
  int computerWins,
  int draws,
  int winStreak,
  int bestWinStreak,
});

/// Чтение и запись статистики в SharedPreferences.
class StatsService {
  static const _snapshot = 'stats.snapshot.v1';
  static const _gamesPlayed = 'stats.gamesPlayed';
  static const _playerWins = 'stats.playerWins';
  static const _computerWins = 'stats.computerWins';
  static const _draws = 'stats.draws';
  static const _winStreak = 'stats.winStreak';
  static const _bestWinStreak = 'stats.bestWinStreak';

  /// Загружает сохранённую статистику (нули при отсутствии данных).
  Future<SavedStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = prefs.getString(_snapshot);
    if (snapshot != null) {
      try {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map<String, dynamic>) {
          int value(String key) {
            final raw = decoded[key];
            return raw is int && raw >= 0 ? raw : 0;
          }

          return (
            gamesPlayed: value('gamesPlayed'),
            playerWins: value('playerWins'),
            computerWins: value('computerWins'),
            draws: value('draws'),
            winStreak: value('winStreak'),
            bestWinStreak: value('bestWinStreak'),
          );
        }
      } on FormatException {
        // Повреждённый снимок не блокирует миграцию со старых ключей.
      }
    }

    return (
      gamesPlayed: prefs.getInt(_gamesPlayed) ?? 0,
      playerWins: prefs.getInt(_playerWins) ?? 0,
      computerWins: prefs.getInt(_computerWins) ?? 0,
      draws: prefs.getInt(_draws) ?? 0,
      winStreak: prefs.getInt(_winStreak) ?? 0,
      bestWinStreak: prefs.getInt(_bestWinStreak) ?? 0,
    );
  }

  /// Сохраняет [stats] в SharedPreferences.
  Future<void> save(StatsState stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'gamesPlayed': stats.gamesPlayed,
      'playerWins': stats.playerWins,
      'computerWins': stats.computerWins,
      'draws': stats.draws,
      'winStreak': stats.winStreak,
      'bestWinStreak': stats.bestWinStreak,
    });
    final saved = await prefs.setString(_snapshot, encoded);
    if (!saved) throw StateError('Не удалось сохранить статистику');
  }
}
