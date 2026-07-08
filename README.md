# Durak (podkidnoy)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Russian / Русский: [README.ru.md](README.ru.md)

**Podkidnoy Durak** — classic Russian card game for Android: **Flutter**, **Riverpod**, **shared_preferences** for statistics.

## Features

- **Rules** — 36-card deck (6–A), 6 cards each, trump suit, attack/defense, throwing cards of matching rank, pass when all pairs are beaten.
- **Opponent** — computer AI (minimal defense card, low non-trump attacks, trumps saved for later).
- **UX** — animated table and turn banner, fan-shaped hand, haptic feedback, semantic labels for cards, continue vs new game on the home screen.
- **Statistics** — wins, losses, draws, win rate, current and best win streak (persisted locally).
- **Screens** — Home (menu, rules dialog), Game, Statistics.

## Stack

| Area | Choice |
|------|--------|
| UI | Flutter Material 3 |
| State | flutter_riverpod (`StateNotifier`) |
| Persistence | shared_preferences |
| Game logic | Pure Dart services (`GameService`, `AIService`) |

See `pubspec.yaml` for SDK and dependency versions.

## Requirements

- **Flutter SDK** 3.0+ (stable; CI uses 3.44.x)
- **JDK 17+** (for Android builds)
- **Android SDK** with compile/target SDK as required by the Flutter SDK
- Android device or emulator

## CI & automation

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [CI](.github/workflows/ci.yml) | push / PR to `main`, manual | `flutter analyze`, `flutter test`, release APK build |
| [Security](.github/workflows/security.yml) | push / PR to `main`, weekly | OSV dependency scan, CodeQL (Dart) |
| [Release](.github/workflows/release.yml) | tag `v*` | Upload-keystore–signed **APK + AAB** + GitHub Release (requires secrets) |

[Dependabot](.github/dependabot.yml) opens weekly PRs for pub dependencies and GitHub Actions.

## Build & run

```bash
flutter pub get
flutter run
```

Debug APK:

```bash
flutter build apk --debug
```

For **signed release** builds, see [Release signing](#release-signing).

## Release signing

`android/app/build.gradle` loads **`keystore.properties`** from the repository root. If it exists, **`signingConfigs.upload`** is applied to **`release`**; otherwise **`release`** uses the **debug** keystore so fresh clones and CI still build installable APKs.

### 1. Create an upload keystore (once)

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep **`upload-keystore.jks`** and passwords in a password manager; **back up** the file — without it you cannot ship compatible updates.

### 2. Local signed `release` builds

1. Copy [`keystore.properties.example`](keystore.properties.example) to **`keystore.properties`** in the **repository root** (gitignored).
2. Set `storeFile`, passwords, and `keyAlias` to match your keystore.
3. Run:

```bash
flutter build apk --release
flutter build appbundle --release
```

Or use the helper script:

```bash
./scripts/build_release.sh
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk` and `build/app/outputs/bundle/release/app-release.aab`.

If **`keystore.properties` is missing**, `release` still signs with the **debug** keystore — **do not** publish that build to an app store.

### 3. GitHub Actions tag releases (`v*`)

Configure these **repository secrets** (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `RELEASE_KEYSTORE_BASE64` | Base64 of `upload-keystore.jks` (e.g. `base64 -i upload-keystore.jks \| tr -d '\n'` on macOS) |
| `RELEASE_STORE_PASSWORD` | Keystore password |
| `RELEASE_KEY_ALIAS` | Key alias (e.g. `upload`) |
| `RELEASE_KEY_PASSWORD` | Key password |

The [Release](.github/workflows/release.yml) workflow writes `keystore.properties` and `upload-keystore.jks` on the runner, then builds signed **APK + AAB**, and attaches **`durak-<tag>.apk`** and **`.aab`** to the GitHub Release. If any secret is missing, the workflow **fails** with an error message.

## Project layout

| Path | Role |
|------|------|
| `lib/models/` | `PlayingCard`, `Deck`, `GameState`, `Player` |
| `lib/services/` | `GameService` (rules), `AIService`, `StatsService` |
| `lib/providers/` | `GameStateNotifier`, Riverpod providers |
| `lib/screens/` | Home, Game, Statistics |
| `lib/widgets/` | Card, hand, table, controls |
| `test/` | Unit tests for services and provider |

## Testing

```bash
flutter analyze
flutter test
```

| Suite | Location | Coverage |
|-------|----------|----------|
| Game rules | `test/game_service_test.dart` | Attack, defense, pass, draw, card draw order |
| AI | `test/ai_service_test.dart` | Attack selection without mutating hand |
| Provider | `test/game_provider_test.dart` | Computer timer cancellation on new game |
| Stats | `test/stats_service_test.dart` | SharedPreferences round-trip |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/build_release.sh` | Signed APK/AAB → path from `store-upload.dir` (see `store-upload.dir.example`) |

## Contact

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either **version 3** of the License, or (at your option) any later version.

See the [`LICENSE`](LICENSE) file for the full GPLv3 text.

Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
