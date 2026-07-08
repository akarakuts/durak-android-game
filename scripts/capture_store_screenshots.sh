#!/usr/bin/env bash
# Скриншоты для карточки RuStore: полный кадр → без status bar → 9:16 (1080×1920).
# Готовые файлы: docs/store-screenshots/store_${SHOT_W}x${SHOT_H}/
# Копия: STORE_COPY_TO или store-copy.dir (см. store-copy.dir.example); SKIP_STORE_COPY=1 — не копировать.
set -euo pipefail
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${PROJ_ROOT}/docs/store-screenshots"
PKG="ru.akarakuts.durak"
ACT="${PKG}/.MainActivity"
STRIP_STATUS_TOP_PX="${STRIP_STATUS_TOP_PX:-156}"
SHOT_W="${SHOT_W:-1080}"
SHOT_H="${SHOT_H:-1920}"
SHOT_CROP_VERTICAL="${SHOT_CROP_VERTICAL:-bottom}"
SHOT_OUT="${OUT}/store_${SHOT_W}x${SHOT_H}"

resolve_copy_dest() {
  if [[ -n "${STORE_COPY_TO:-}" ]]; then
    printf '%s' "$STORE_COPY_TO"
    return
  fi
  local f="$PROJ_ROOT/store-copy.dir"
  if [[ -f "$f" ]]; then
    head -1 "$f" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    return
  fi
  printf ''
}

COPY_DEST="$(resolve_copy_dest)"

mkdir -p "$OUT" "$SHOT_OUT"

wait_boot() {
  local i boot
  for i in $(seq 1 60); do
    boot="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    [[ "$boot" == "1" ]] && return 0
    sleep 2
  done
  echo "capture_store_screenshots: эмулятор не загрузился" >&2
  return 1
}

cap() {
  local out="$1"
  adb shell input keyevent 224 2>/dev/null || true
  sleep 0.25
  adb shell screencap -p /sdcard/_store_cap.png
  adb pull /sdcard/_store_cap.png "$out" >/dev/null
  adb shell rm -f /sdcard/_store_cap.png 2>/dev/null || true
}

tap_by_label() {
  local label="$1"
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 || true
  adb pull /sdcard/ui.xml /tmp/durak-ui.xml >/dev/null 2>&1 || true
  local coords
  coords="$(
    python3 - "$label" <<'PY'
import re, sys
label = sys.argv[1]
try:
    xml = open("/tmp/durak-ui.xml", encoding="utf-8", errors="replace").read()
except OSError:
    sys.exit(0)
for m in re.finditer(
    r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml
):
    if m.group(1) == label:
        x = (int(m.group(2)) + int(m.group(4))) // 2
        y = (int(m.group(3)) + int(m.group(5))) // 2
        print(f"{x} {y}")
        break
PY
  )"
  if [[ -n "$coords" ]]; then
    adb shell input tap $coords
    return 0
  fi
  return 1
}

tap_menu() {
  local label="$1" fallback_x="$2" fallback_y="$3"
  if tap_by_label "$label"; then
    sleep 1.2
    return 0
  fi
  adb shell input tap "$fallback_x" "$fallback_y"
  sleep 1.2
}

fresh_home() {
  adb shell pm clear "$PKG" >/dev/null 2>&1 || true
  sleep 0.5
  adb shell am force-stop "$PKG" >/dev/null 2>&1 || true
  sleep 0.3
  adb shell am start -n "$ACT" >/dev/null
  sleep 7
}

strip_status_bar() {
  local f="$1" top="${STRIP_STATUS_TOP_PX}" tmp="${f}.strip.tmp.png" w h nh
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "capture_store_screenshots: ffmpeg не найден — status bar не обрезан: $f" >&2
    return 0
  fi
  w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  nh=$((h - top))
  if [[ -z "$w" || -z "$h" || "$nh" -lt 32 ]]; then
    echo "capture_store_screenshots: не удалось определить размер: $f" >&2
    return 0
  fi
  ffmpeg -y -nostdin -hide_banner -loglevel error -i "$f" -vf "crop=${w}:${nh}:0:${top}" -frames:v 1 "$tmp"
  mv "$tmp" "$f"
}

store_portrait_9x16() {
  local src="$1" dst="$2" w="${SHOT_W}" h="${SHOT_H}" cy_expr
  case "${SHOT_CROP_VERTICAL}" in
    top) cy_expr="0" ;;
    center) cy_expr="(ih-${h})/2" ;;
    bottom) cy_expr="ih-${h}" ;;
    *)
      echo "capture_store_screenshots: SHOT_CROP_VERTICAL=${SHOT_CROP_VERTICAL} — допустимо top|center|bottom" >&2
      return 1
      ;;
  esac
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "capture_store_screenshots: ffmpeg не найден" >&2
    return 1
  fi
  ffmpeg -y -nostdin -hide_banner -loglevel error -i "$src" \
    -vf "scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h}:(iw-${w})/2:${cy_expr}" \
    -frames:v 1 "$dst"
}

adb devices | grep -q emulator || {
  echo "capture_store_screenshots: нет подключённого эмулятора" >&2
  exit 1
}
wait_boot

adb shell input keyevent 224 2>/dev/null || true
sleep 0.35

fresh_home
cap "$OUT/01_ru_home.png"

fresh_home
tap_menu "Новая игра" 540 1480
sleep 2
cap "$OUT/02_ru_game.png"

fresh_home
tap_menu "Новая игра" 540 1480
sleep 2
adb shell input tap 320 2140
sleep 1
cap "$OUT/03_ru_gameplay.png"

fresh_home
tap_menu "Статистика" 540 1560
sleep 1.5
cap "$OUT/04_ru_statistics.png"

fresh_home
tap_menu "Правила" 540 1640
sleep 1.2
cap "$OUT/05_ru_rules.png"

for f in "$OUT"/0*.png; do
  [[ -f "$f" ]] || continue
  strip_status_bar "$f"
done

rm -f "$SHOT_OUT"/*.png
for f in "$OUT"/0*.png; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f" .png)
  store_portrait_9x16 "$f" "$SHOT_OUT/${base}.png"
done

echo "Готово: $OUT"
echo "9:16 (${SHOT_W}×${SHOT_H}): $SHOT_OUT"
ls -la "$SHOT_OUT"/*.png

if [[ "${SKIP_STORE_COPY:-}" != "1" && -n "$COPY_DEST" ]]; then
  mkdir -p "$COPY_DEST"
  cp -f "$SHOT_OUT"/*.png "$COPY_DEST/"
  echo "Скопировано в: $COPY_DEST"
  ls -la "$COPY_DEST"/*.png
elif [[ "${SKIP_STORE_COPY:-}" != "1" ]]; then
  echo "capture_store_screenshots: копирование пропущено (нет STORE_COPY_TO / store-copy.dir)" >&2
fi
