// Нижняя панель действий: взять карты, пас, новая игра.
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../l10n/app_strings.dart';
import '../utils/constants.dart';

/// Кнопка действия в зависимости от [GamePhase] и чья очередь ходить.
class GameControls extends StatelessWidget {
  final GamePhase phase;
  final bool isHumanTurn;
  final bool canPass;
  final VoidCallback? onTakeCards;
  final VoidCallback? onPass;
  final VoidCallback? onNewGame;

  const GameControls({
    super.key,
    required this.phase,
    required this.isHumanTurn,
    this.canPass = false,
    this.onTakeCards,
    this.onPass,
    this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == GamePhase.gameOver) {
      return _button(Icons.refresh_rounded, AppStrings.newGame, onNewGame);
    }
    if (phase == GamePhase.defending && isHumanTurn) {
      return _button(
        Icons.file_download_outlined,
        AppStrings.takeCards,
        onTakeCards,
        danger: true,
      );
    }
    if (phase == GamePhase.taking && isHumanTurn) {
      return _button(
        Icons.done_rounded,
        AppStrings.finishThrowIn,
        onPass,
      );
    }
    if (phase == GamePhase.attacking && isHumanTurn && canPass) {
      return _button(Icons.done_all_rounded, AppStrings.pass, onPass);
    }
    return const SizedBox(height: 52);
  }

  Widget _button(
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor:
                danger ? AppConstants.dangerColor : AppConstants.accentColor,
            foregroundColor: danger ? Colors.white : const Color(0xFF052F2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
