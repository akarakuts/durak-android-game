// Веер карт в руке игрока с overlap и подсветкой доступных ходов.
import 'package:flutter/material.dart';
import '../models/card.dart';
import 'card_widget.dart';

/// Горизонтальный веер [CardWidget] с адаптивным шагом и наклоном.
class HandWidget extends StatelessWidget {
  final List<PlayingCard> cards;
  final ValueChanged<PlayingCard>? onCardTap;
  final bool isPlayable;
  final List<PlayingCard> playableCards;
  final bool compact;

  const HandWidget({
    super.key,
    required this.cards,
    this.onCardTap,
    this.isPlayable = false,
    this.playableCards = const [],
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 108 : 132,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = compact ? 62.0 : 76.0;
          final cardHeight = compact ? 92.0 : 112.0;
          final step = cards.length <= 1
              ? cardWidth
              : ((constraints.maxWidth - cardWidth - 24) / (cards.length - 1))
                  .clamp(28.0, 58.0);
          final contentWidth = cardWidth + step * (cards.length - 1);
          final start =
              ((constraints.maxWidth - contentWidth) / 2).clamp(12.0, 28.0);
          return Stack(
            clipBehavior: Clip.none,
            children: List.generate(cards.length, (index) {
              final card = cards[index];
              final canPlay = !isPlayable || playableCards.contains(card);
              final center = (cards.length - 1) / 2;
              final angle = ((index - center) * 0.025).clamp(-0.08, 0.08);
              return Positioned(
                left: start + index * step,
                top: canPlay ? 3 : 15,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.bottomCenter,
                  child: CardWidget(
                    card: card,
                    width: cardWidth,
                    height: cardHeight,
                    isEnabled: !isPlayable || canPlay,
                    onTap: canPlay ? () => onCardTap?.call(card) : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
