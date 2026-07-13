/// CardBackPattern — орнамент рубашки карты для [CardWidget].
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Орнамент рубашки карты: сетка и крест в стиле иконки приложения.
class CardBackPattern extends StatelessWidget {
  final double size;

  const CardBackPattern({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.18;
    final gap = size * 0.06;
    final accent = size * 0.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: List.generate(
              4,
              (_) => Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: AppConstants.warmColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(tile * 0.15),
                ),
              ),
            ),
          ),
          Container(
            width: accent,
            height: accent,
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(accent * 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
