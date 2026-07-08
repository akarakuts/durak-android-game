import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    final winRate = gameState.gamesPlayed > 0
        ? ((gameState.playerWins / gameState.gamesPlayed) * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Статистика'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildStatCard(
            'Всего игр',
            '${gameState.gamesPlayed}',
            Icons.games,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Победы',
            '${gameState.playerWins}',
            Icons.emoji_events,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Поражения',
            '${gameState.computerWins}',
            Icons.sentiment_dissatisfied,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Ничьи',
            '${gameState.draws}',
            Icons.handshake_outlined,
            Colors.tealAccent,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Процент побед',
            '$winRate%',
            Icons.percent,
            Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Текущая серия',
            '${gameState.winStreak}',
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Лучшая серия',
            '${gameState.bestWinStreak}',
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
