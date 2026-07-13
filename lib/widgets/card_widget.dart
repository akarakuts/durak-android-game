/// Виджет одной карты: лицо/рубашка, Semantics и тактильная отдача.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart';
import '../l10n/app_strings.dart';
import '../utils/constants.dart';
import 'card_back_pattern.dart';

/// Отрисовка [PlayingCard] с анимацией выбора и доступностью.
class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool isEnabled;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTap,
    this.width = 70,
    this.height = 100,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    void activate() {
      unawaited(HapticFeedback.selectionClick());
      onTap?.call();
    }

    return Semantics(
      button: onTap != null,
      enabled: isEnabled,
      excludeSemantics: true,
      label: card.faceUp
          ? '${_rankSemanticName(card.rank)}, ${_suitSemanticName(card.suit)}'
          : AppStrings.cardBackSemantic,
      child: FocusableActionDetector(
        enabled: onTap != null && isEnabled,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onTap == null ? null : activate,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isEnabled ? 1 : 0.42,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              height: height,
              transform: Matrix4.translationValues(0, isSelected ? -15 : 0, 0),
              decoration: BoxDecoration(
                color: card.faceUp
                    ? AppConstants.ivoryColor
                    : AppConstants.cardBackColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppConstants.accentColor
                      : AppConstants.ivoryColor.withValues(alpha: 0.75),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: card.faceUp ? _buildFaceUp() : _buildFaceDown(),
            ),
          ),
        ),
      ),
    );
  }

  String _rankSemanticName(Rank rank) => switch (rank) {
        Rank.six => 'шестёрка',
        Rank.seven => 'семёрка',
        Rank.eight => 'восьмёрка',
        Rank.nine => 'девятка',
        Rank.ten => 'десятка',
        Rank.jack => 'валет',
        Rank.queen => 'дама',
        Rank.king => 'король',
        Rank.ace => 'туз',
      };

  String _suitSemanticName(Suit suit) => switch (suit) {
        Suit.clubs => 'трефы',
        Suit.diamonds => 'бубны',
        Suit.hearts => 'червы',
        Suit.spades => 'пики',
      };

  Widget _buildFaceUp() {
    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 4,
          child: _buildCorner(),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildCorner(),
          ),
        ),
        Center(
          child: Text(
            card.rankName,
            style: TextStyle(
              fontSize: width * 0.32,
              fontWeight: FontWeight.bold,
              color: card.isRed ? Colors.red : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rankName,
          style: TextStyle(
            fontSize: width * 0.16,
            fontWeight: FontWeight.bold,
            color: card.isRed ? Colors.red : Colors.black,
          ),
        ),
        Text(
          card.suitSymbol,
          style: TextStyle(
            fontSize: width * 0.19,
            color: card.isRed ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFaceDown() {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppConstants.cardBackColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppConstants.warmColor.withValues(alpha: 0.55),
        ),
      ),
      child: Center(
        child: CardBackPattern(size: width * 0.62),
      ),
    );
  }
}
