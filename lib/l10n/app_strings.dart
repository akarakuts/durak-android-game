/// Централизованный словарь пользовательских строк (русская локаль).
///
/// Чистый Dart без зависимости от Flutter, чтобы его можно было
/// использовать как в моделях, так и в виджетах. При появлении второй
/// локали класс заменяется на сгенерированные ARB-строки.
class AppStrings {
  AppStrings._();

  // Приложение ----------------------------------------------------------
  static const String appName = 'Подкидной дурак';
  static const String homeTitle = 'Подкидной дурак';
  static const String homeSubtitle = 'Классическая карточная игра';

  // Меню ----------------------------------------------------------------
  static const String continueGame = 'Продолжить';
  static const String newGame = 'Новая игра';
  static const String statistics = 'Статистика';
  static const String rules = 'Правила';
  static const String ok = 'Понятно';

  // Правила -------------------------------------------------------------
  static const String rulesTitle = 'Правила игры';
  static const String rulesGoalTitle = 'Цель игры';
  static const String rulesGoal = 'Избавиться от всех карт первым.';
  static const String rulesStartTitle = 'Начало игры';
  static const String rulesStart =
      'Каждому игроку раздаётся по 6 карт. Одна карта переворачивается — '
      'это козырь.';
  static const String rulesFlowTitle = 'Ход игры';
  static const String rulesFlow = '1. Атакующий кладёт карту на стол.\n'
      '2. Защищающийся должен покрыть карту старшего ранга той же масти '
      'или козырём.\n'
      '3. Если не может — забирает все карты со стола.\n'
      '4. Можно подкидывать карты того же ранга, что уже на столе.';
  static const String rulesTrumpTitle = 'Козырь';
  static const String rulesTrump =
      'Козырная масть бьёт любую другую масть, независимо от ранга.';

  // Стол и карты --------------------------------------------------------
  static const String tableEmptyHint = 'Выберите карту для первого хода';
  static const String cardBackSemantic = 'Карта рубашкой вверх';

  // Игроки --------------------------------------------------------------
  static const String humanPlayerName = 'Игрок';
  static const String computerPlayerName = 'Компьютер';
  static const String computerTurn = 'Ход компьютера';
  static const String computerThinking = 'Соперник думает…';

  // Ходы игрока ---------------------------------------------------------
  static const String turnAttack = 'Ваш ход · Атака';
  static const String turnAttackHintFirst = 'Выберите карту';
  static const String turnAttackHintMore = 'Подкиньте или нажмите «Пас»';
  static const String turnDefense = 'Ваш ход · Защита';
  static const String turnDefenseHint = 'Отбейте карту или возьмите';
  static const String turnThrowIn = 'Соперник берёт';
  static const String turnThrowInHint = 'Подкиньте карты или завершите';
  static const String computerThrowingIn = 'Компьютер докидывает карты…';

  // Кнопки управления ---------------------------------------------------
  static const String takeCards = 'Взять карты';
  static const String pass = 'Бито · Пас';
  static const String finishThrowIn = 'Завершить подкидывание';
  static const String toMenu = 'В меню';

  // Итоги партии --------------------------------------------------------
  static const String victory = 'Победа!';
  static const String draw = 'Ничья';
  static const String computerWon = 'В этот раз — компьютер';
  static const String drawDetail = 'Карты закончились одновременно';
  static const String goodGame = 'Хорошая партия';

  // Статистика ----------------------------------------------------------
  static const String statsTotalGames = 'Всего игр';
  static const String statsWins = 'Победы';
  static const String statsLosses = 'Поражения';
  static const String statsDraws = 'Ничьи';
  static const String statsWinRate = 'Процент побед';
  static const String statsCurrentStreak = 'Текущая серия';
  static const String statsBestStreak = 'Лучшая серия';

  /// Подпись количества карт игрока/компьютера.
  static String cardsCount(int count) => '$count карт';

  /// Семантическое описание колоды и козыря.
  static String deckSemantic(int remaining, String trump) =>
      'В колоде $remaining карт. Козырь $trump';
}
