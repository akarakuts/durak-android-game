/// Игровые константы «Подкидного дурака».
///
/// Чистый Dart без зависимости от Flutter, чтобы их можно было использовать
/// в моделях и сервисах, не подтягивая Material.
class GameRules {
  GameRules._();

  /// Размер полной колоды (36 карт: 6–туз, 4 масти).
  static const int deckSize = 36;

  /// Карт на одного игрока при раздаче и максимальный размер руки.
  static const int cardsPerPlayer = 6;

  /// Максимальное число атакующих карт за один раунд.
  static const int maxAttackCards = 6;

  /// Карт в колоде сразу после раздачи (36 − 12).
  static const int postDealDeckSize = deckSize - 2 * cardsPerPlayer;

  /// Задержка обычного хода компьютера, мс.
  static const int computerActionDelayMs = 800;

  /// Задержка первого хода компьютера в новой партии, мс.
  static const int computerFirstMoveDelayMs = 500;
}
