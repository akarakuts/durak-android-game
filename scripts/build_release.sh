#!/usr/bin/env bash
# Подписанный release: Flutter APK/AAB + копирование в каталог из store-upload.dir или STORE_UPLOAD_DIR.
set -euo pipefail

PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ_ROOT"

resolve_upload_dir() {
  if [[ -n "${STORE_UPLOAD_DIR:-}" ]]; then
    printf '%s' "$STORE_UPLOAD_DIR"
    return
  fi
  local f="$PROJ_ROOT/store-upload.dir"
  if [[ -f "$f" ]]; then
    head -1 "$f" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    return
  fi
  echo "build_release: задайте STORE_UPLOAD_DIR или store-upload.dir (см. store-upload.dir.example)" >&2
  exit 1
}

OUT="$(resolve_upload_dir)"
if [[ -z "$OUT" ]]; then
  echo "build_release: пустой каталог в STORE_UPLOAD_DIR / store-upload.dir" >&2
  exit 1
fi

if [[ ! -f "$PROJ_ROOT/keystore.properties" ]]; then
  echo "build_release: keystore.properties не найден — release с debug-подписью (не для публикации)" >&2
fi

version_name="$(
  sed -n 's/^version:[[:space:]]*\([0-9].*\)/\1/p' pubspec.yaml | head -1 | awk '{print $1}'
)"
if [[ -z "$version_name" ]]; then
  echo "build_release: не удалось прочитать version из pubspec.yaml" >&2
  exit 1
fi

flutter pub get
flutter build apk --release
flutter build appbundle --release

apk_src="build/app/outputs/flutter-apk/app-release.apk"
aab_src="build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "$apk_src" ]]; then
  echo "build_release: APK не найден: $apk_src" >&2
  exit 1
fi
if [[ ! -f "$aab_src" ]]; then
  echo "build_release: AAB не найден: $aab_src" >&2
  exit 1
fi

mkdir -p "$OUT"
apk_dst="$OUT/durak-${version_name}.apk"
aab_dst="$OUT/durak-${version_name}.aab"
cp -f "$apk_src" "$apk_dst"
cp -f "$aab_src" "$aab_dst"

echo "Release (${version_name}): $OUT"
ls -la "$apk_dst" "$aab_dst"
