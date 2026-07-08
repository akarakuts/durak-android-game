/// Неизменяемое состояние статистики (персистентные тоталы).
///
/// Хранится отдельно от игрового состояния, чтобы избежать двойного
/// источника истины: счетчики живут только здесь и сохраняются через
/// [StatsService].
class StatsState {
  final int gamesPlayed;
  final int playerWins;
  final int computerWins;
  final int draws;
  final int winStreak;
  final int bestWinStreak;

  const StatsState({
    this.gamesPlayed = 0,
    this.playerWins = 0,
    this.computerWins = 0,
    this.draws = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
  });

  StatsState copyWith({
    int? gamesPlayed,
    int? playerWins,
    int? computerWins,
    int? draws,
    int? winStreak,
    int? bestWinStreak,
  }) =>
      StatsState(
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        playerWins: playerWins ?? this.playerWins,
        computerWins: computerWins ?? this.computerWins,
        draws: draws ?? this.draws,
        winStreak: winStreak ?? this.winStreak,
        bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      );

  /// Процент побед в диапазоне 0–100.
  double get winRate => gamesPlayed > 0 ? (playerWins / gamesPlayed) * 100 : 0;
}
