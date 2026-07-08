import 'card.dart';
import 'deck.dart';
import 'player.dart';
import '../l10n/app_strings.dart';
import '../utils/game_rules.dart';

const _notProvided = Object();

/// Фаза хода в партии.
enum GamePhase { waiting, attacking, defending, taking, gameOver }

/// Итог партии.
enum GameResult { none, playerWins, computerWins, draw }

/// Неизменяемая пара «атака — защита» на столе.
class TableCard {
  final PlayingCard attackCard;
  final PlayingCard? defenseCard;

  const TableCard({required this.attackCard, this.defenseCard});

  /// Возвращает копию с заменёнными полями.
  TableCard copyWith({
    PlayingCard? attackCard,
    Object? defenseCard = _notProvided,
  }) =>
      TableCard(
        attackCard: attackCard ?? this.attackCard,
        defenseCard: identical(defenseCard, _notProvided)
            ? this.defenseCard
            : defenseCard as PlayingCard?,
      );

  /// Атака отбита.
  bool get isDefended => defenseCard != null;
}

/// Неизменяемое состояние игры.
///
/// Все изменения выполняются через [copyWith]; сами поля не мутируются.
/// Статистика хранится отдельно в [StatsState].
class GameState {
  final Deck deck;
  final Player humanPlayer;
  final Player computerPlayer;
  final List<TableCard> tableCards;
  final GamePhase phase;
  final bool isHumanTurn;
  final GameResult result;

  GameState({
    Deck? deck,
    Player? humanPlayer,
    Player? computerPlayer,
    List<TableCard>? tableCards,
    this.phase = GamePhase.waiting,
    this.isHumanTurn = true,
    this.result = GameResult.none,
  })  : deck = deck ?? Deck(),
        humanPlayer = humanPlayer ??
            Player(
              name: AppStrings.humanPlayerName,
              type: PlayerType.human,
            ),
        computerPlayer = computerPlayer ??
            Player(
              name: AppStrings.computerPlayerName,
              type: PlayerType.computer,
            ),
        tableCards = List<TableCard>.unmodifiable(tableCards ?? const []);

  /// Возвращает копию состояния с заменёнными полями.
  GameState copyWith({
    Deck? deck,
    Player? humanPlayer,
    Player? computerPlayer,
    List<TableCard>? tableCards,
    GamePhase? phase,
    bool? isHumanTurn,
    GameResult? result,
  }) =>
      GameState(
        deck: deck ?? this.deck,
        humanPlayer: humanPlayer ?? this.humanPlayer,
        computerPlayer: computerPlayer ?? this.computerPlayer,
        tableCards: tableCards ?? this.tableCards,
        phase: phase ?? this.phase,
        isHumanTurn: isHumanTurn ?? this.isHumanTurn,
        result: result ?? this.result,
      );

  /// Масть козыря текущей колоды.
  Suit? get trumpSuit => deck.trumpSuit;

  /// Стол пуст.
  bool get isTableEmpty => tableCards.isEmpty;

  /// Может ли человек пасовать (завершить отбитый раунд) сейчас.
  bool get canPass {
    if (phase != GamePhase.attacking) return false;
    return !isTableEmpty && isHumanTurn;
  }

  /// Может ли человек завершить докидывание карт берущему компьютеру.
  bool get canHumanFinishThrowIn =>
      phase == GamePhase.taking && isHumanTurn && tableCards.isNotEmpty;

  /// Может ли человек подкинуть ещё одну карту.
  ///
  /// Лимит атак — не более 6 и не более карт, имевшихся у защитника на
  /// старте раунда (оценивается как текущая рука + уже отбитые карты).
  bool get canHumanAddAttack {
    if (tableCards.isEmpty) return true;
    final defenderStartingHand = computerPlayer.cardCount +
        tableCards.where((tc) => tc.defenseCard != null).length;
    return tableCards.length <
        defenderStartingHand.clamp(0, GameRules.maxAttackCards);
  }

  /// Карты, которыми человек может сыграть в текущий момент.
  List<PlayingCard> get playableCards {
    if ((phase == GamePhase.attacking || phase == GamePhase.taking) &&
        isHumanTurn) {
      return _getAttackCards();
    }
    if (phase == GamePhase.defending && isHumanTurn) return _getDefenseCards();
    return [];
  }

  List<PlayingCard> _getAttackCards() {
    if (!canHumanAddAttack) return [];
    if (tableCards.isEmpty) return humanPlayer.hand;

    final ranksOnTable = tableCards.map((tc) => tc.attackCard.rank).toSet();
    for (final tc in tableCards) {
      if (tc.defenseCard != null) ranksOnTable.add(tc.defenseCard!.rank);
    }
    return humanPlayer.hand
        .where((card) => ranksOnTable.contains(card.rank))
        .toList();
  }

  List<PlayingCard> _getDefenseCards() {
    if (tableCards.isEmpty) return [];
    final lastAttack = tableCards.last.attackCard;
    return humanPlayer.hand
        .where((card) => humanPlayer.canBeat(lastAttack, card, trumpSuit))
        .toList();
  }
}
