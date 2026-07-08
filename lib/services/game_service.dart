import 'package:meta/meta.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../utils/game_rules.dart';
import 'ai_service.dart';

/// Чистые правила игры «Подкидной дурак».
///
/// Все методы принимают [GameState] и возвращают новое состояние, не мутируя
/// переданное. Это позволяет использовать сервис внутри StateNotifier без
/// ручного копирования. Счётчики статистики здесь не ведутся — за них
/// отвечает [StatsNotifier].
class GameService {
  final AIService _aiService;

  GameService({AIService? aiService}) : _aiService = aiService ?? AIService();

  /// Начинает новую партию на основе [state]: переворачивает козырь, раздаёт
  /// по 6 карт, определяет, кто ходит первым.
  GameState startNewGame(GameState state) {
    var deck = state.deck.flipTrumpCard();
    var human = state.humanPlayer;
    var computer = state.computerPlayer;

    final humanDeal = deck.deal(GameRules.cardsPerPlayer);
    deck = humanDeal.deck;
    human = human.addCards(humanDeal.dealt);

    final computerDeal = deck.deal(GameRules.cardsPerPlayer);
    deck = computerDeal.deck;
    computer = computer.addCards(computerDeal.dealt);

    human = human.sortHand(deck.trumpSuit);
    computer = computer.sortHand(deck.trumpSuit);

    final isHumanTurn = humanStarts(human, computer, deck.trumpSuit);
    return state.copyWith(
      deck: deck,
      humanPlayer: human,
      computerPlayer: computer,
      phase: GamePhase.attacking,
      isHumanTurn: isHumanTurn,
      result: GameResult.none,
      tableCards: const [],
    );
  }

  /// Ход человека в атаке картой [card].
  GameState humanAttack(GameState state, PlayingCard card) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return state;
    if (!state.humanPlayer.hand.contains(card)) return state;
    if (!state.canHumanAddAttack) return state;

    if (state.tableCards.isNotEmpty) {
      final ranksOnTable =
          state.tableCards.map((tc) => tc.attackCard.rank).toSet();
      for (final tc in state.tableCards) {
        if (tc.defenseCard != null) ranksOnTable.add(tc.defenseCard!.rank);
      }
      if (!ranksOnTable.contains(card.rank)) return state;
    }

    final next = state.copyWith(
      humanPlayer: state.humanPlayer.removeCard(card),
      tableCards: [...state.tableCards, TableCard(attackCard: card)],
      phase: GamePhase.defending,
      isHumanTurn: false,
    );
    return _checkWin(next);
  }

  /// Ход человека в защите картой [defenseCard] против последней атаки.
  GameState humanDefend(GameState state, PlayingCard defenseCard) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return state;

    final lastTableCard = state.tableCards.last;
    if (lastTableCard.isDefended) return state;
    if (!state.humanPlayer.hand.contains(defenseCard)) return state;

    final attackCard = lastTableCard.attackCard;
    if (!state.humanPlayer.canBeat(attackCard, defenseCard, state.trumpSuit)) {
      return state;
    }

    final newTableCards = [
      ...state.tableCards.sublist(0, state.tableCards.length - 1),
      lastTableCard.copyWith(defenseCard: defenseCard),
    ];
    final next = state.copyWith(
      humanPlayer: state.humanPlayer.removeCard(defenseCard),
      tableCards: newTableCards,
    );

    if (next.tableCards.every((tc) => tc.isDefended)) {
      final defenderStartingHand =
          next.humanPlayer.cardCount + next.tableCards.length;
      final attackLimit =
          defenderStartingHand.clamp(0, GameRules.maxAttackCards);
      if (next.tableCards.length >= attackLimit ||
          next.computerPlayer.isEmpty) {
        return _finishRound(next, humanAttacksNext: true);
      }
      return next.copyWith(phase: GamePhase.attacking, isHumanTurn: false);
    }
    return next.copyWith(phase: GamePhase.attacking, isHumanTurn: true);
  }

  /// Человек объявляет, что забирает карты. Перед завершением раунда компьютер
  /// получает возможность докинуть дополнительные карты подходящего ранга.
  GameState humanTakeCards(GameState state) {
    if (state.phase != GamePhase.defending || !state.isHumanTurn) return state;
    return state.copyWith(phase: GamePhase.taking, isHumanTurn: false);
  }

  /// Человек докидывает карту компьютеру, который решил забрать стол.
  GameState humanThrowIn(GameState state, PlayingCard card) {
    if (state.phase != GamePhase.taking || !state.isHumanTurn) return state;
    if (!state.humanPlayer.hand.contains(card)) return state;
    if (!state.canHumanAddAttack || !_matchesRankOnTable(state, card)) {
      return state;
    }
    return state.copyWith(
      humanPlayer: state.humanPlayer.removeCard(card),
      tableCards: [...state.tableCards, TableCard(attackCard: card)],
    );
  }

  /// Завершает докидывание человека и передаёт стол компьютеру.
  GameState humanFinishThrowIn(GameState state) {
    if (!state.canHumanFinishThrowIn) return state;
    return _completeTaking(state, humanTakes: false);
  }

  /// Человек пасует, завершая отбитый раунд.
  GameState humanPass(GameState state) {
    if (state.phase != GamePhase.attacking || !state.isHumanTurn) return state;
    if (state.tableCards.isEmpty) return state;
    if (state.tableCards.every((tc) => tc.isDefended)) {
      return _finishRound(state, humanAttacksNext: false);
    }
    return state;
  }

  /// Ход компьютера в атаке.
  GameState computerAttack(GameState state) {
    if (state.phase != GamePhase.attacking || state.isHumanTurn) return state;
    if (state.computerPlayer.isEmpty) return state;

    if (state.tableCards.isNotEmpty) {
      final defenderStartingHand = state.humanPlayer.cardCount +
          state.tableCards.where((tc) => tc.isDefended).length;
      final attackLimit =
          defenderStartingHand.clamp(0, GameRules.maxAttackCards);
      if (state.tableCards.length >= attackLimit) {
        return _finishRound(state, humanAttacksNext: true);
      }
    }

    final card = _aiService.selectAttackCard(
      state.computerPlayer.hand,
      state.tableCards,
      state.trumpSuit,
    );
    if (card == null) {
      if (state.tableCards.isNotEmpty &&
          state.tableCards.every((tc) => tc.isDefended)) {
        return _finishRound(state, humanAttacksNext: true);
      }
      return state;
    }

    final next = state.copyWith(
      computerPlayer: state.computerPlayer.removeCard(card),
      tableCards: [...state.tableCards, TableCard(attackCard: card)],
      phase: GamePhase.defending,
      isHumanTurn: true,
    );
    return _checkWin(next);
  }

  /// Ход компьютера в защите.
  GameState computerDefend(GameState state) {
    if (state.phase != GamePhase.defending || state.isHumanTurn) return state;

    final lastTableCard = state.tableCards.last;
    if (lastTableCard.isDefended) return state;

    final defenseCard = _aiService.selectDefenseCard(
      state.computerPlayer.hand,
      lastTableCard.attackCard,
      state.trumpSuit,
    );
    if (defenseCard == null) {
      return state.copyWith(phase: GamePhase.taking, isHumanTurn: true);
    }

    final newTableCards = [
      ...state.tableCards.sublist(0, state.tableCards.length - 1),
      lastTableCard.copyWith(defenseCard: defenseCard),
    ];
    final next = state.copyWith(
      computerPlayer: state.computerPlayer.removeCard(defenseCard),
      tableCards: newTableCards,
    );

    if (next.tableCards.every((tc) => tc.isDefended)) {
      final defenderStartingHand =
          next.computerPlayer.cardCount + next.tableCards.length;
      final attackLimit =
          defenderStartingHand.clamp(0, GameRules.maxAttackCards);
      if (next.tableCards.length >= attackLimit ||
          next.humanPlayer.isEmpty ||
          !next.canHumanAddAttack) {
        return _finishRound(next, humanAttacksNext: false);
      }
      return next.copyWith(phase: GamePhase.attacking, isHumanTurn: true);
    }
    return next;
  }

  /// Компьютер докидывает карту человеку, объявившему взятие. Если подходящей
  /// карты больше нет или достигнут лимит, взятие завершается автоматически.
  GameState computerThrowIn(GameState state) {
    if (state.phase != GamePhase.taking || state.isHumanTurn) return state;

    final defenderStartingHand = state.humanPlayer.cardCount +
        state.tableCards.where((tc) => tc.isDefended).length;
    final attackLimit = defenderStartingHand.clamp(0, GameRules.maxAttackCards);
    if (state.tableCards.length >= attackLimit) {
      return _completeTaking(state, humanTakes: true);
    }

    final card = _aiService.selectAttackCard(
      state.computerPlayer.hand,
      state.tableCards,
      state.trumpSuit,
    );
    if (card == null) return _completeTaking(state, humanTakes: true);

    return state.copyWith(
      computerPlayer: state.computerPlayer.removeCard(card),
      tableCards: [...state.tableCards, TableCard(attackCard: card)],
    );
  }

  GameState _completeTaking(GameState state, {required bool humanTakes}) {
    final cardsToTake = <PlayingCard>[];
    for (final tc in state.tableCards) {
      cardsToTake.add(tc.attackCard);
      if (tc.defenseCard != null) cardsToTake.add(tc.defenseCard!);
    }

    var next = humanTakes
        ? state.copyWith(
            humanPlayer: state.humanPlayer
                .addCards(cardsToTake)
                .sortHand(state.trumpSuit),
            tableCards: const [],
          )
        : state.copyWith(
            computerPlayer: state.computerPlayer
                .addCards(cardsToTake)
                .sortHand(state.trumpSuit),
            tableCards: const [],
          );
    next = _drawCards(next, humanFirst: !humanTakes);
    next = _checkWin(next);
    if (next.result != GameResult.none) return next;
    return next.copyWith(
      phase: GamePhase.attacking,
      isHumanTurn: !humanTakes,
    );
  }

  bool _matchesRankOnTable(GameState state, PlayingCard card) {
    for (final tableCard in state.tableCards) {
      if (tableCard.attackCard.rank == card.rank ||
          tableCard.defenseCard?.rank == card.rank) {
        return true;
      }
    }
    return false;
  }

  /// Добирает карты до 6 каждому, начиная с того, кто не атаковал.
  GameState _drawCards(GameState state, {required bool humanFirst}) {
    var deck = state.deck;
    var human = state.humanPlayer;
    var computer = state.computerPlayer;

    bool needsDraw() =>
        human.cardCount < GameRules.cardsPerPlayer ||
        computer.cardCount < GameRules.cardsPerPlayer;

    while (deck.remainingCards > 0 && needsDraw()) {
      if (humanFirst) {
        if (human.cardCount < GameRules.cardsPerPlayer &&
            deck.remainingCards > 0) {
          final d = deck.drawCard();
          deck = d.deck;
          if (d.card != null) human = human.addCards([d.card!]);
        }
        if (computer.cardCount < GameRules.cardsPerPlayer &&
            deck.remainingCards > 0) {
          final d = deck.drawCard();
          deck = d.deck;
          if (d.card != null) computer = computer.addCards([d.card!]);
        }
      } else {
        if (computer.cardCount < GameRules.cardsPerPlayer &&
            deck.remainingCards > 0) {
          final d = deck.drawCard();
          deck = d.deck;
          if (d.card != null) computer = computer.addCards([d.card!]);
        }
        if (human.cardCount < GameRules.cardsPerPlayer &&
            deck.remainingCards > 0) {
          final d = deck.drawCard();
          deck = d.deck;
          if (d.card != null) human = human.addCards([d.card!]);
        }
      }
    }

    human = human.sortHand(deck.trumpSuit);
    computer = computer.sortHand(deck.trumpSuit);
    return state.copyWith(
      deck: deck,
      humanPlayer: human,
      computerPlayer: computer,
    );
  }

  /// Кто ходит первым: владелец младшего козыря. При равенстве — человек.
  @visibleForTesting
  static bool humanStarts(Player human, Player computer, Suit? trumpSuit) {
    if (trumpSuit == null) return true;

    int? lowestTrump(List<PlayingCard> hand) {
      final values =
          hand.where((c) => c.suit == trumpSuit).map((c) => c.rankValue);
      if (values.isEmpty) return null;
      return values.reduce((lowest, value) => value < lowest ? value : lowest);
    }

    final humanTrump = lowestTrump(human.hand);
    final computerTrump = lowestTrump(computer.hand);
    if (humanTrump == null) return false;
    if (computerTrump == null) return true;
    return humanTrump <= computerTrump;
  }

  /// Завершает раунд: добор, очистка стола, проверка победы, передача хода.
  GameState _finishRound(GameState state, {required bool humanAttacksNext}) {
    var next = _drawCards(state, humanFirst: !humanAttacksNext);
    next = next.copyWith(tableCards: const []);
    next = _checkWin(next);
    if (next.result != GameResult.none) return next;
    return next.copyWith(
      phase: GamePhase.attacking,
      isHumanTurn: humanAttacksNext,
    );
  }

  /// Проверяет условие победы (только когда колода пуста и стол чист).
  /// Устанавливает итог и фазу; учёт статистики ведёт [StatsNotifier].
  GameState _checkWin(GameState state) {
    if (!state.deck.isEmpty || state.tableCards.isNotEmpty) return state;

    if (state.humanPlayer.isEmpty && state.computerPlayer.isEmpty) {
      return state.copyWith(
        result: GameResult.draw,
        phase: GamePhase.gameOver,
      );
    } else if (state.humanPlayer.isEmpty) {
      return state.copyWith(
        result: GameResult.playerWins,
        phase: GamePhase.gameOver,
      );
    } else if (state.computerPlayer.isEmpty) {
      return state.copyWith(
        result: GameResult.computerWins,
        phase: GamePhase.gameOver,
      );
    }
    return state;
  }
}
