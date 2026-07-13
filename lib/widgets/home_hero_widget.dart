/// HomeHeroWidget — декоративный веер карт на главном экране.
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../utils/constants.dart';
import 'card_widget.dart';

/// Декоративный веер карт на главном экране (статичный, без жестов).
class HomeHeroWidget extends StatelessWidget {
  const HomeHeroWidget({super.key});

  static const PlayingCard _trumpCard = PlayingCard(
    suit: Suit.spades,
    rank: Rank.ace,
    faceUp: true,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Подкидной дурак',
      child: SizedBox(
        width: 228,
        height: 156,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _fanCard(angle: -0.38, dx: -58, dy: 10, scale: 0.88),
            _fanCard(angle: -0.16, dx: -30, dy: 4, scale: 0.92),
            _fanCard(angle: 0.16, dx: 30, dy: 4, scale: 0.92),
            _fanCard(angle: 0.38, dx: 58, dy: 10, scale: 0.88),
            Transform.translate(
              offset: const Offset(0, -8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.accentColor.withValues(alpha: 0.35),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CardWidget(
                  card: _trumpCard,
                  width: 94,
                  height: 132,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.accentColor.withValues(alpha: 0.55),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '♠',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstants.ivoryColor,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Козырь',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.ivoryColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fanCard({
    required double angle,
    required double dx,
    required double dy,
    required double scale,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: const CardWidget(
            card: PlayingCard(
              suit: Suit.hearts,
              rank: Rank.six,
              faceUp: false,
            ),
            width: 78,
            height: 110,
          ),
        ),
      ),
    );
  }
}
