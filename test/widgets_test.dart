import 'package:durak_game/l10n/app_strings.dart';
import 'package:durak_game/models/card.dart';
import 'package:durak_game/models/deck.dart';
import 'package:durak_game/models/game.dart';
import 'package:durak_game/models/player.dart';
import 'package:durak_game/models/stats_state.dart';
import 'package:durak_game/providers/game_provider.dart';
import 'package:durak_game/providers/stats_provider.dart';
import 'package:durak_game/services/game_service.dart';
import 'package:durak_game/services/stats_service.dart';
import 'package:durak_game/screens/home_screen.dart';
import 'package:durak_game/screens/game_screen.dart';
import 'package:durak_game/screens/stats_screen.dart';
import 'package:durak_game/widgets/game_controls.dart';
import 'package:durak_game/widgets/card_widget.dart';
import 'package:durak_game/widgets/table_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedGameService extends GameService {
  final GameState startState;
  _ScriptedGameService(this.startState);

  @override
  GameState startNewGame(GameState state) => startState;
}

class _ScriptedStatsService extends StatsService {
  final SavedStats loaded;
  _ScriptedStatsService(this.loaded);

  @override
  Future<SavedStats> load() async => loaded;

  @override
  Future<void> save(StatsState stats) async {}
}

const _six = PlayingCard(suit: Suit.clubs, rank: Rank.six);

GameState _freshGame() => GameState(
      deck: Deck.withCards(
        List.generate(24, (_) => _six),
        trumpCard: const PlayingCard(suit: Suit.hearts, rank: Rank.seven),
      ),
      humanPlayer: Player(
        name: AppStrings.humanPlayerName,
        type: PlayerType.human,
        hand: [_six, _six, _six, _six, _six, _six],
      ),
      computerPlayer: Player(
        name: AppStrings.computerPlayerName,
        type: PlayerType.computer,
        hand: [_six, _six, _six, _six, _six, _six],
      ),
      phase: GamePhase.attacking,
      isHumanTurn: true,
      result: GameResult.none,
    );

ProviderContainer _container(GameState game, SavedStats stats) {
  final overrides = [
    gameServiceProvider.overrideWithValue(_ScriptedGameService(game)),
    statsServiceProvider.overrideWithValue(_ScriptedStatsService(stats)),
  ];
  final container = ProviderContainer(overrides: overrides);
  container.read(gameStateProvider.notifier).startNewGame();
  return container;
}

Widget _scoped(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('HomeScreen показывает меню без активной партии', (tester) async {
    final container = _container(
      _freshGame(),
      const (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeTitle), findsOneWidget);
    expect(find.text(AppStrings.newGame), findsOneWidget);
    expect(find.text(AppStrings.statistics), findsOneWidget);
    expect(find.text(AppStrings.rules), findsOneWidget);
    expect(find.text(AppStrings.continueGame), findsNothing);
  });

  testWidgets('HomeScreen показывает Продолжить при активной партии',
      (tester) async {
    final active = _freshGame().copyWith(
      tableCards: const [TableCard(attackCard: _six)],
    );
    final container = _container(
      active,
      const (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.continueGame), findsOneWidget);
  });

  testWidgets('GameScreen рисует стол и подсказку первого хода',
      (tester) async {
    final container = _container(
      _freshGame(),
      const (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const GameScreen()));
    await tester.pump();

    expect(find.text(AppStrings.tableEmptyHint), findsOneWidget);
    expect(find.text(AppStrings.turnAttack), findsOneWidget);
    expect(find.text(AppStrings.computerPlayerName), findsOneWidget);
  });

  testWidgets('GameScreen показывает экран победы', (tester) async {
    final won = _freshGame().copyWith(
      result: GameResult.playerWins,
      phase: GamePhase.gameOver,
    );
    final container = _container(
      won,
      const (
        gamesPlayed: 1,
        playerWins: 1,
        computerWins: 0,
        draws: 0,
        winStreak: 1,
        bestWinStreak: 1,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const GameScreen()));
    await tester.pump();

    expect(find.text(AppStrings.victory), findsOneWidget);
    expect(find.text(AppStrings.newGame), findsOneWidget);
  });

  testWidgets('StatsScreen показывает сохранённые значения', (tester) async {
    final container = _container(
      _freshGame(),
      const (
        gamesPlayed: 5,
        playerWins: 3,
        computerWins: 1,
        draws: 1,
        winStreak: 2,
        bestWinStreak: 3,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const StatsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('60.0%'), findsOneWidget);
  });

  testWidgets('GameControls в защите показывает Взять карты', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            phase: GamePhase.defending,
            isHumanTurn: true,
            onTakeCards: () {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.takeCards), findsOneWidget);
  });

  testWidgets('GameControls с пасом показывает Бито Пас', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            phase: GamePhase.attacking,
            isHumanTurn: true,
            canPass: true,
            onPass: () {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.pass), findsOneWidget);
  });

  testWidgets('GameControls конец игры показывает Новая игра', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            phase: GamePhase.gameOver,
            isHumanTurn: false,
            onNewGame: () {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.newGame), findsOneWidget);
  });

  testWidgets('GameControls при взятии показывает завершение докидывания',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            phase: GamePhase.taking,
            isHumanTurn: true,
            onPass: () {},
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.finishThrowIn), findsOneWidget);
  });

  testWidgets('TableWidget отображает пару атака-защита', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TableWidget(
            tableCards: [
              TableCard(
                attackCard: PlayingCard(suit: Suit.clubs, rank: Rank.six),
                defenseCard: PlayingCard(suit: Suit.clubs, rank: Rank.seven),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CardWidget), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('главный экран не переполняется при размере 480x320',
      (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(
      _freshGame(),
      const (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const HomeScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('игровой экран не переполняется при размере 480x320',
      (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(
      _freshGame(),
      const (
        gamesPlayed: 0,
        playerWins: 0,
        computerWins: 0,
        draws: 0,
        winStreak: 0,
        bestWinStreak: 0,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_scoped(container, const GameScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('карта имеет локализованную семантическую подпись',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardWidget(
          card: PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        ),
      ),
    );

    expect(find.bySemanticsLabel('туз, червы'), findsOneWidget);
  });
}
