import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/stats_provider.dart';
import '../utils/constants.dart';

/// Экран статистики партий. Читает данные из отдельного [StatsNotifier].
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsNotifierProvider);
    final winRate = stats.winRate.toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text(AppStrings.statistics),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildStatCard(
            AppStrings.statsTotalGames,
            '${stats.gamesPlayed}',
            Icons.games,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsWins,
            '${stats.playerWins}',
            Icons.emoji_events,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsLosses,
            '${stats.computerWins}',
            Icons.sentiment_dissatisfied,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsDraws,
            '${stats.draws}',
            Icons.handshake_outlined,
            Colors.tealAccent,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsWinRate,
            '$winRate%',
            Icons.percent,
            Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsCurrentStreak,
            '${stats.winStreak}',
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            AppStrings.statsBestStreak,
            '${stats.bestWinStreak}',
            Icons.star,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
