import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final hasActiveGame = game.result == GameResult.none &&
        (game.tableCards.isNotEmpty ||
            game.deck.remainingCards < 24 ||
            game.humanPlayer.cardCount != 6 ||
            game.computerPlayer.cardCount != 6);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 92,
                height: 116,
                decoration: BoxDecoration(
                  color: AppConstants.ivoryColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  size: 46,
                  color: AppConstants.secondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'ПОДКИДНОЙ ДУРАК',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Классическая карточная игра',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            if (hasActiveGame) ...[
              _buildMenuButton(
                context,
                'Продолжить',
                Icons.play_arrow_rounded,
                () => Navigator.pushReplacementNamed(context, '/game'),
                primary: true,
              ),
              const SizedBox(height: 12),
            ],
            _buildMenuButton(
              context,
              'Новая игра',
              Icons.refresh_rounded,
              () {
                notifier.startNewGame();
                Navigator.pushReplacementNamed(context, '/game');
              },
              primary: !hasActiveGame,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              'Статистика',
              Icons.bar_chart,
              () => Navigator.pushNamed(context, '/stats'),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              'Правила',
              Icons.help_outline,
              () => _showRules(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool primary = false,
  }) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? AppConstants.accentColor
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor:
              primary ? const Color(0xFF052F2C) : AppConstants.ivoryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Правила игры'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Цель игры',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('Избавиться от всех карт первым.'),
              SizedBox(height: 16),
              Text(
                'Начало игры',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('Каждому игроку раздаётся по 6 карт. '
                  'Одна карта переворачивается — это козырь.'),
              SizedBox(height: 16),
              Text(
                'Ход игры',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('1. Атакующий кладёт карту на стол.\n'
                  '2. Защищающийся должен покрыть карту старшего ранга той же масти или козырём.\n'
                  '3. Если не может — забирает все карты со стола.\n'
                  '4. Можно подкидывать карты того же ранга, что уже на столе.'),
              SizedBox(height: 16),
              Text(
                'Козырь',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('Козырная масть бьёт любую другую масть, '
                  'независимо от ранга.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
