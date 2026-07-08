import 'dart:math';

import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/deck.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('100 детерминированных партий завершаются без нарушения инвариантов',
      () {
    for (var seed = 0; seed < 100; seed++) {
      final service = GameService();
      var state = service.startNewGame(
        GameState(deck: Deck(random: Random(seed))),
      );

      for (var step = 0;
          step < 2000 && state.result == GameResult.none;
          step++) {
        _expectValidState(state, seed: seed, step: step);
        final previous = state;

        if (state.isHumanTurn) {
          state = switch (state.phase) {
            GamePhase.attacking => state.playableCards.isNotEmpty
                ? service.humanAttack(state, state.playableCards.first)
                : service.humanPass(state),
            GamePhase.defending => state.playableCards.isNotEmpty
                ? service.humanDefend(state, state.playableCards.first)
                : service.humanTakeCards(state),
            GamePhase.taking => state.playableCards.isNotEmpty
                ? service.humanThrowIn(state, state.playableCards.first)
                : service.humanFinishThrowIn(state),
            GamePhase.waiting || GamePhase.gameOver => state,
          };
        } else {
          state = switch (state.phase) {
            GamePhase.attacking => service.computerAttack(state),
            GamePhase.defending => service.computerDefend(state),
            GamePhase.taking => service.computerThrowIn(state),
            GamePhase.waiting || GamePhase.gameOver => state,
          };
        }

        expect(
          identical(state, previous),
          isFalse,
          reason: 'Партия $seed зависла на шаге $step (${state.phase})',
        );
      }

      _expectValidState(state, seed: seed, step: 2000);
      expect(
        state.phase,
        GamePhase.gameOver,
        reason: 'Партия $seed не завершилась за 2000 шагов',
      );
      expect(state.deck.isEmpty, isTrue);
      expect(state.tableCards, isEmpty);
    }
  });
}

void _expectValidState(
  GameState state, {
  required int seed,
  required int step,
}) {
  final reason = 'Партия $seed, шаг $step';
  expect(state.tableCards.length, lessThanOrEqualTo(6), reason: reason);

  final undefended =
      state.tableCards.where((card) => !card.isDefended).toList();
  if (state.phase != GamePhase.taking) {
    expect(undefended.length, lessThanOrEqualTo(1), reason: reason);
  }
  if (undefended.length == 1) {
    expect(state.tableCards.last, same(undefended.single), reason: reason);
  }

  for (final tableCard in state.tableCards.where((card) => card.isDefended)) {
    final defense = tableCard.defenseCard!;
    final beatsBySuit = defense.suit == tableCard.attackCard.suit &&
        defense.rankValue > tableCard.attackCard.rankValue;
    final beatsByTrump = defense.suit == state.trumpSuit &&
        tableCard.attackCard.suit != state.trumpSuit;
    expect(beatsBySuit || beatsByTrump, isTrue, reason: reason);
  }

  final liveCards = <PlayingCard>[
    ...state.humanPlayer.hand,
    ...state.computerPlayer.hand,
    for (final tableCard in state.tableCards) ...[
      tableCard.attackCard,
      if (tableCard.defenseCard case final defense?) defense,
    ],
  ];
  expect(liveCards.toSet().length, liveCards.length, reason: reason);
}
