import '../models/card.dart';
import '../models/game.dart';
import 'ai_service.dart';

class GameService {
  final AIService _aiService;

  GameService({AIService? aiService}) : _aiService = aiService ?? AIService();

  void startNewGame(GameState state) {
    state.deck.flipTrumpCard();
    state.humanPlayer.addCards(state.deck.deal(6));
    state.computerPlayer.addCards(state.deck.deal(6));
    state.humanPlayer.sortHand(state.trumpSuit);
    state.computerPlayer.sortHand(state.trumpSuit);
    state.phase = GamePhase.attacking;
    state.isHumanTurn = _humanStarts(state);
    state.result = GameResult.none;
    state.tableCards.clear();
  }

  void humanAttack(GameState state, PlayingCard card) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    if (!state.humanPlayer.hand.contains(card)) return;
    if (!state.canHumanAddAttack) return;

    if (state.tableCards.isNotEmpty) {
      final ranksOnTable =
          state.tableCards.map((tc) => tc.attackCard.rank).toSet();
      for (final tc in state.tableCards) {
        if (tc.defenseCard != null) {
          ranksOnTable.add(tc.defenseCard!.rank);
        }
      }
      if (!ranksOnTable.contains(card.rank)) return;
    }

    state.humanPlayer.removeCard(card);
    state.tableCards.add(TableCard(attackCard: card));
    state.phase = GamePhase.defending;
    state.isHumanTurn = false;

    _checkWin(state);
  }

  void humanDefend(GameState state, PlayingCard defenseCard) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;

    final lastTableCard = state.tableCards.last;
    if (lastTableCard.isDefended) return;

    if (!state.humanPlayer.hand.contains(defenseCard)) return;

    final attackCard = lastTableCard.attackCard;
    if (!state.humanPlayer.canBeat(attackCard, defenseCard, state.trumpSuit)) {
      return;
    }

    state.humanPlayer.removeCard(defenseCard);
    lastTableCard.defenseCard = defenseCard;

    if (state.tableCards.every((tc) => tc.isDefended)) {
      final defenderStartingHand =
          state.humanPlayer.cardCount + state.tableCards.length;
      final attackLimit = defenderStartingHand.clamp(0, 6);
      if (state.tableCards.length >= attackLimit ||
          state.computerPlayer.isEmpty) {
        _finishRound(state, humanAttacksNext: true);
      } else {
        state.phase = GamePhase.attacking;
        state.isHumanTurn = false;
      }
    } else {
      state.phase = GamePhase.attacking;
      state.isHumanTurn = true;
    }
  }

  void humanTakeCards(GameState state) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return;

    final cardsToTake = <PlayingCard>[];
    for (final tc in state.tableCards) {
      cardsToTake.add(tc.attackCard);
      if (tc.defenseCard != null) {
        cardsToTake.add(tc.defenseCard!);
      }
    }

    state.humanPlayer.addCards(cardsToTake);
    state.humanPlayer.sortHand(state.trumpSuit);
    state.tableCards.clear();

    _drawCards(state, humanFirst: false);

    state.phase = GamePhase.attacking;
    state.isHumanTurn = false;
  }

  void humanPass(GameState state) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return;
    if (state.tableCards.isEmpty) return;

    if (state.tableCards.every((tc) => tc.isDefended)) {
      _finishRound(state, humanAttacksNext: false);
    }
  }

  void computerAttack(GameState state) {
    if (state.phase != GamePhase.attacking || state.isHumanTurn) return;
    if (state.computerPlayer.isEmpty) return;

    if (state.tableCards.isNotEmpty) {
      final defenderStartingHand = state.humanPlayer.cardCount +
          state.tableCards.where((card) => card.isDefended).length;
      final attackLimit = defenderStartingHand.clamp(0, 6);
      if (state.tableCards.length >= attackLimit) {
        _finishRound(state, humanAttacksNext: true);
        return;
      }
    }

    final card = _aiService.selectAttackCard(
      state.computerPlayer.hand,
      state.tableCards,
      state.trumpSuit,
    );
    if (card == null) {
      if (state.tableCards.isNotEmpty &&
          state.tableCards.every((card) => card.isDefended)) {
        _finishRound(state, humanAttacksNext: true);
      }
      return;
    }

    state.computerPlayer.removeCard(card);
    state.tableCards.add(TableCard(attackCard: card));
    state.phase = GamePhase.defending;
    state.isHumanTurn = true;

    _checkWin(state);
  }

  void computerDefend(GameState state) {
    if (state.phase != GamePhase.defending || state.isHumanTurn) return;

    final lastTableCard = state.tableCards.last;
    if (lastTableCard.isDefended) return;

    final defenseCard = _aiService.selectDefenseCard(
      state.computerPlayer.hand,
      lastTableCard.attackCard,
      state.trumpSuit,
    );
    if (defenseCard == null) {
      _computerTakeCards(state);
      return;
    }

    state.computerPlayer.removeCard(defenseCard);
    lastTableCard.defenseCard = defenseCard;

    if (state.tableCards.every((tc) => tc.isDefended)) {
      final defenderStartingHand =
          state.computerPlayer.cardCount + state.tableCards.length;
      final attackLimit = defenderStartingHand.clamp(0, 6);
      if (state.tableCards.length >= attackLimit ||
          state.humanPlayer.isEmpty ||
          !state.canHumanAddAttack) {
        _finishRound(state, humanAttacksNext: false);
      } else {
        state.phase = GamePhase.attacking;
        state.isHumanTurn = true;
      }
    }
  }

  void _computerTakeCards(GameState state) {
    final cardsToTake = <PlayingCard>[];
    for (final tc in state.tableCards) {
      cardsToTake.add(tc.attackCard);
      if (tc.defenseCard != null) {
        cardsToTake.add(tc.defenseCard!);
      }
    }

    state.computerPlayer.addCards(cardsToTake);
    state.computerPlayer.sortHand(state.trumpSuit);
    state.tableCards.clear();

    _drawCards(state, humanFirst: true);

    state.phase = GamePhase.attacking;
    state.isHumanTurn = true;
  }

  void _drawCards(GameState state, {required bool humanFirst}) {
    while (state.deck.remainingCards > 0 &&
        (state.humanPlayer.cardCount < 6 ||
            state.computerPlayer.cardCount < 6)) {
      final players = humanFirst
          ? [state.humanPlayer, state.computerPlayer]
          : [state.computerPlayer, state.humanPlayer];
      for (final player in players) {
        if (player.cardCount < 6 && state.deck.remainingCards > 0) {
          final card = state.deck.drawCard();
          if (card != null) player.addCards([card]);
        }
      }
    }
    state.humanPlayer.sortHand(state.trumpSuit);
    state.computerPlayer.sortHand(state.trumpSuit);
  }

  bool _humanStarts(GameState state) {
    final trumpSuit = state.trumpSuit;
    if (trumpSuit == null) return true;

    int? lowestTrump(List<PlayingCard> hand) {
      final values = hand
          .where((card) => card.suit == trumpSuit)
          .map((card) => card.rankValue);
      if (values.isEmpty) return null;
      return values.reduce((lowest, value) => value < lowest ? value : lowest);
    }

    final humanTrump = lowestTrump(state.humanPlayer.hand);
    final computerTrump = lowestTrump(state.computerPlayer.hand);
    if (humanTrump == null) return false;
    if (computerTrump == null) return true;
    return humanTrump <= computerTrump;
  }

  void _finishRound(GameState state, {required bool humanAttacksNext}) {
    _drawCards(state, humanFirst: !humanAttacksNext);
    state.tableCards.clear();
    _checkWin(state);
    if (state.result == GameResult.none) {
      state.phase = GamePhase.attacking;
      state.isHumanTurn = humanAttacksNext;
    }
  }

  void _checkWin(GameState state) {
    if (!state.deck.isEmpty || state.tableCards.isNotEmpty) return;

    if (state.humanPlayer.isEmpty && state.computerPlayer.isEmpty) {
      state.result = GameResult.draw;
      state.phase = GamePhase.gameOver;
      state.gamesPlayed++;
      state.draws++;
      state.winStreak = 0;
    } else if (state.humanPlayer.isEmpty) {
      state.result = GameResult.playerWins;
      state.phase = GamePhase.gameOver;
      state.gamesPlayed++;
      state.playerWins++;
      state.winStreak++;
      if (state.winStreak > state.bestWinStreak) {
        state.bestWinStreak = state.winStreak;
      }
    } else if (state.computerPlayer.isEmpty) {
      state.result = GameResult.computerWins;
      state.phase = GamePhase.gameOver;
      state.gamesPlayed++;
      state.computerWins++;
      state.winStreak = 0;
    }
  }
}
