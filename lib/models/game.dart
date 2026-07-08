import 'card.dart';
import 'deck.dart';
import 'player.dart';

enum GamePhase {
  waiting,
  attacking,
  defending,
  gameOver,
}

enum GameResult { none, playerWins, computerWins, draw }

class TableCard {
  final PlayingCard attackCard;
  PlayingCard? defenseCard;

  TableCard({required this.attackCard, this.defenseCard});

  TableCard.copy(TableCard other)
      : attackCard = other.attackCard,
        defenseCard = other.defenseCard;

  bool get isDefended => defenseCard != null;
}

class GameState {
  final Deck deck;
  final Player humanPlayer;
  final Player computerPlayer;
  final List<TableCard> tableCards;
  GamePhase phase;
  bool isHumanTurn;
  GameResult result;
  int gamesPlayed;
  int playerWins;
  int computerWins;
  int draws;
  int winStreak;
  int bestWinStreak;

  GameState({
    Deck? deck,
    Player? humanPlayer,
    Player? computerPlayer,
    List<TableCard>? tableCards,
    this.phase = GamePhase.waiting,
    this.isHumanTurn = true,
    this.result = GameResult.none,
    this.gamesPlayed = 0,
    this.playerWins = 0,
    this.computerWins = 0,
    this.draws = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
  })  : deck = deck ?? Deck(),
        humanPlayer =
            humanPlayer ?? Player(name: 'Игрок', type: PlayerType.human),
        computerPlayer = computerPlayer ??
            Player(name: 'Компьютер', type: PlayerType.computer),
        tableCards = List<TableCard>.of(tableCards ?? const []);

  GameState.copy(GameState other)
      : deck = Deck.copy(other.deck),
        humanPlayer = Player.copy(other.humanPlayer),
        computerPlayer = Player.copy(other.computerPlayer),
        tableCards = other.tableCards.map(TableCard.copy).toList(),
        phase = other.phase,
        isHumanTurn = other.isHumanTurn,
        result = other.result,
        gamesPlayed = other.gamesPlayed,
        playerWins = other.playerWins,
        computerWins = other.computerWins,
        draws = other.draws,
        winStreak = other.winStreak,
        bestWinStreak = other.bestWinStreak;

  Suit? get trumpSuit => deck.trumpSuit;

  bool get isTableEmpty => tableCards.isEmpty;

  bool get canPass {
    if (phase != GamePhase.attacking) return false;
    return !isTableEmpty && isHumanTurn;
  }

  bool get canHumanAddAttack {
    if (tableCards.isEmpty) return true;
    final defenderStartingHand = computerPlayer.cardCount +
        tableCards.where((card) => card.defenseCard != null).length;
    return tableCards.length < defenderStartingHand.clamp(0, 6);
  }

  List<PlayingCard> get playableCards {
    if (phase == GamePhase.attacking && isHumanTurn) {
      return _getAttackCards();
    }
    if (phase == GamePhase.defending && isHumanTurn) {
      return _getDefenseCards();
    }
    return [];
  }

  List<PlayingCard> _getAttackCards() {
    if (!canHumanAddAttack) return [];
    if (tableCards.isEmpty) {
      return humanPlayer.hand;
    }

    final ranksOnTable = tableCards.map((tc) => tc.attackCard.rank).toSet();
    if (tableCards.any((tc) => tc.defenseCard != null)) {
      for (final tc in tableCards) {
        if (tc.defenseCard != null) {
          ranksOnTable.add(tc.defenseCard!.rank);
        }
      }
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
