import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/game_rules.dart';
import '../widgets/home_hero_widget.dart';

/// Главный экран: меню игры.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final hasActiveGame = game.phase != GamePhase.waiting &&
        game.result == GameResult.none &&
        (game.tableCards.isNotEmpty ||
            game.deck.remainingCards < GameRules.postDealDeckSize ||
            game.humanPlayer.cardCount != GameRules.cardsPerPlayer ||
            game.computerPlayer.cardCount != GameRules.cardsPerPlayer);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    (constraints.maxHeight - 40).clamp(0, double.infinity),
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HomeHeroWidget(),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.homeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppStrings.homeSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (hasActiveGame) ...[
                    _buildMenuButton(
                      context,
                      AppStrings.continueGame,
                      Icons.play_arrow_rounded,
                      () => unawaited(
                        Navigator.pushReplacementNamed(context, '/game'),
                      ),
                      primary: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildMenuButton(
                    context,
                    AppStrings.newGame,
                    Icons.refresh_rounded,
                    () {
                      notifier.startNewGame();
                      unawaited(
                        Navigator.pushReplacementNamed(context, '/game'),
                      );
                    },
                    primary: !hasActiveGame,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    context,
                    AppStrings.statistics,
                    Icons.bar_chart,
                    () => unawaited(Navigator.pushNamed(context, '/stats')),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    context,
                    AppStrings.rules,
                    Icons.help_outline,
                    () => _showRules(context),
                  ),
                ],
              ),
            ),
          ),
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
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: SizedBox(
          width: double.infinity,
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
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.rulesTitle),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.rulesGoalTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(AppStrings.rulesGoal),
                SizedBox(height: 16),
                Text(
                  AppStrings.rulesStartTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(AppStrings.rulesStart),
                SizedBox(height: 16),
                Text(
                  AppStrings.rulesFlowTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(AppStrings.rulesFlow),
                SizedBox(height: 16),
                Text(
                  AppStrings.rulesTrumpTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(AppStrings.rulesTrump),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.ok),
            ),
          ],
        ),
      ),
    );
  }
}
