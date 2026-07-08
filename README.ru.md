# Подкидной дурак

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

English: [README.md](README.md)

**Подкидной дурак** — классическая карточная игра для Android: **Flutter**, **Riverpod**, статистика в **shared_preferences**.

## Возможности

- **Правила** — колода 36 карт (6–туз), по 6 карт, козырь, атака/защита, подкидывание карт того же достоинства, «бито» после отбоя.
- **Соперник** — ИИ (минимальная карта для защиты, слабые некозырные атаки, козыри бережёт).
- **Интерфейс** — анимации стола и баннера хода, веер карт в руке, тактильная отдача, семантика для доступности, «Продолжить» / «Новая игра» на главном экране.
- **Статистика** — победы, поражения, ничьи, процент побед, текущая и лучшая серия (локально).
- **Экраны** — главное меню (правила в диалоге), игра, статистика.

## Требования и сборка

Как в [README.md](README.md): Flutter 3.0+, JDK 17+, `flutter pub get`, `flutter run`. Подпись **release** — в англ. README, раздел [Release signing](README.md#release-signing).

Подписанный release локально или через скрипт:

```bash
./scripts/build_release.sh
```

Каталог для копирования APK/AAB — `store-upload.dir` (см. `store-upload.dir.example`).

## CI (GitHub Actions)

Как в англ. README: [CI](.github/workflows/ci.yml) (`flutter analyze`, `flutter test`, сборка APK), [Security](.github/workflows/security.yml) (OSV + CodeQL), [Release](.github/workflows/release.yml) по тегу `v*` (подписанные APK/AAB в GitHub Release). Секреты и подпись — в [README.md](README.md#release-signing). [Dependabot](.github/dependabot.yml) — еженедельные PR по pub и Actions.

**Тесты:** правила игры, ИИ, провайдер (отмена таймера), статистика — каталог `test/`. Подробнее — раздел Testing в [README.md](README.md#testing).

## Контакты

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## Лицензия

Программа распространяется на условиях **GNU GPLv3** — полный текст в файле [`LICENSE`](LICENSE).

Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
