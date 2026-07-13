/// Стол: пары атака/защита и горизонтальная прокрутка при длинном раунде.
import 'package:flutter/material.dart';
import '../models/game.dart';
import 'card_widget.dart';
import '../l10n/app_strings.dart';
import '../utils/constants.dart';

/// Список [TableCard] на столе; пустое состояние — подсказка первого хода.
class TableWidget extends StatelessWidget {
  final List<TableCard> tableCards;
  final VoidCallback? onDefend;

  const TableWidget({
    super.key,
    required this.tableCards,
    this.onDefend,
  });

  @override
  Widget build(BuildContext context) {
    if (tableCards.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            AppStrings.tableEmptyHint,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tableCards.length, (index) {
                final tableCard = tableCards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      CardWidget(
                        card: tableCard.attackCard,
                        width: 64,
                        height: 96,
                      ),
                      if (tableCard.defenseCard != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppConstants.accentColor,
                            size: 18,
                          ),
                        ),
                        CardWidget(
                          card: tableCard.defenseCard!,
                          width: 64,
                          height: 96,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
