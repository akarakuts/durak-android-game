import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/card_widget.dart';
import '../widgets/game_controls.dart';
import '../widgets/hand_widget.dart';
import '../widgets/table_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context, state),
            _computerHand(state),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _tableArea(state, notifier),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _turnBanner(state),
            ),
            _humanHand(state, notifier),
            GameControls(
              phase: state.phase,
              isHumanTurn: state.isHumanTurn,
              canPass: state.canPass,
              onTakeCards:
                  state.phase == GamePhase.defending && state.isHumanTurn
                      ? notifier.humanTakeCards
                      : null,
              onPass: state.canPass ? notifier.humanPass : null,
              onNewGame: notifier.startNewGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: [
          IconButton(
            tooltip: 'В меню',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.close_rounded),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppConstants.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Color(0xFF052F2C),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Компьютер',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  '${state.computerPlayer.cardCount} карт',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          _badge(Icons.layers_outlined, '${state.deck.remainingCards}'),
          const SizedBox(width: 6),
          _badge(
            Icons.brightness_2_outlined,
            state.trumpSuit?.suitSymbol ?? '—',
            warm: true,
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String value, {bool warm = false}) {
    final color = warm ? AppConstants.warmColor : AppConstants.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _computerHand(GameState state) {
    final shown = state.computerPlayer.cardCount.clamp(0, 8);
    return SizedBox(
      height: 68,
      child: Center(
        child: SizedBox(
          width: 38 + (shown - 1).clamp(0, 7) * 30,
          child: Stack(
            children: List.generate(
              shown,
              (index) => Positioned(
                left: index * 30,
                child: const CardWidget(
                  card: PlayingCard(
                    suit: Suit.clubs,
                    rank: Rank.six,
                    faceUp: false,
                  ),
                  width: 40,
                  height: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableArea(GameState state, GameStateNotifier notifier) {
    if (state.result != GameResult.none) {
      final won = state.result == GameResult.playerWins;
      final draw = state.result == GameResult.draw;
      return Center(
        key: ValueKey(state.result),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              won
                  ? Icons.emoji_events_rounded
                  : draw
                      ? Icons.handshake_outlined
                      : Icons.replay_rounded,
              size: 64,
              color: won ? AppConstants.warmColor : Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Победа!'
                  : draw
                      ? 'Ничья'
                      : 'В этот раз — компьютер',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(draw ? 'Карты закончились одновременно' : 'Хорошая партия',
                style: const TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      key: ValueKey(
        '${state.tableCards.length}-${state.tableCards.where((card) => card.isDefended).length}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TableWidget(tableCards: state.tableCards),
        ),
        if (state.deck.remainingCards > 0)
          Positioned(
            right: 18,
            bottom: 12,
            child: _deckAndTrump(state),
          ),
      ],
    );
  }

  Widget _deckAndTrump(GameState state) {
    final trump = state.deck.trumpCard;
    return Semantics(
      label:
          'В колоде ${state.deck.remainingCards} карт. Козырь ${trump ?? ''}',
      child: SizedBox(
        width: 112,
        height: 82,
        child: Stack(
          children: [
            if (trump != null)
              Positioned(
                right: 0,
                top: 12,
                child: Transform.rotate(
                  angle: 0.12,
                  child: CardWidget(card: trump, width: 46, height: 68),
                ),
              ),
            const Positioned(
              left: 8,
              top: 5,
              child: CardWidget(
                card: PlayingCard(
                  suit: Suit.clubs,
                  rank: Rank.six,
                  faceUp: false,
                ),
                width: 50,
                height: 72,
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.deck.remainingCards}',
                  style: const TextStyle(
                    color: Color(0xFF052F2C),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnBanner(GameState state) {
    final (icon, title, subtitle, color) =
        switch ((state.phase, state.isHumanTurn)) {
      (GamePhase.attacking, true) => (
          Icons.sports_esports_rounded,
          'Ваш ход · Атака',
          state.tableCards.isEmpty
              ? 'Выберите карту'
              : 'Подкиньте или нажмите «Пас»',
          AppConstants.accentColor,
        ),
      (GamePhase.defending, true) => (
          Icons.shield_outlined,
          'Ваш ход · Защита',
          'Отбейте карту или возьмите',
          AppConstants.warmColor,
        ),
      _ => (
          Icons.hourglass_top_rounded,
          'Ход компьютера',
          'Соперник думает…',
          Colors.white54,
        ),
    };
    return Container(
      key: ValueKey('${state.phase}-${state.isHumanTurn}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _humanHand(GameState state, GameStateNotifier notifier) {
    final canInteract = state.result == GameResult.none &&
        state.isHumanTurn &&
        (state.phase == GamePhase.attacking ||
            state.phase == GamePhase.defending);
    return HandWidget(
      cards: state.humanPlayer.hand,
      isPlayable: canInteract,
      playableCards: state.playableCards,
      onCardTap: canInteract
          ? (card) => state.phase == GamePhase.attacking
              ? notifier.humanAttack(card)
              : notifier.humanDefend(card)
          : null,
    );
  }
}

extension on Suit {
  String get suitSymbol => switch (this) {
        Suit.clubs => '♣',
        Suit.diamonds => '♦',
        Suit.hearts => '♥',
        Suit.spades => '♠',
      };
}
