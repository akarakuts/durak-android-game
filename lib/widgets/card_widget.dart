import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart';
import '../utils/constants.dart';

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
    return Semantics(
      button: onTap != null,
      enabled: isEnabled,
      label: card.faceUp
          ? '${card.rankName} ${card.suitSymbol}'
          : 'Карта рубашкой вверх',
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap?.call();
              },
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
    );
  }

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
            angle: 3.14159,
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
        child: Icon(
          Icons.auto_awesome_mosaic_rounded,
          color: AppConstants.warmColor.withValues(alpha: 0.8),
          size: width * 0.38,
        ),
      ),
    );
  }
}
