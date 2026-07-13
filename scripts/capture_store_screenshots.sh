#!/usr/bin/env bash
# Скриншоты для карточки RuStore: полный кадр → без status bar → 9:16 (1080×1920).
# Готовые файлы: docs/store-screenshots/store_${SHOT_W}x${SHOT_H}/
# Копия: STORE_COPY_TO или store-copy.dir (см. store-copy.dir.example); SKIP_STORE_COPY=1 — не копировать.
set -euo pipefail
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="/opt/homebrew/bin:$ANDROID_HOME/platform-tools:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${PROJ_ROOT}/docs/store-screenshots"
PKG="ru.akarakuts.durak"
ACT="${PKG}/.MainActivity"
STRIP_STATUS_TOP_PX="${STRIP_STATUS_TOP_PX:-96}"
STRIP_NAV_BOTTOM_PX="${STRIP_NAV_BOTTOM_PX:-0}"
SHOT_W="${SHOT_W:-1080}"
SHOT_H="${SHOT_H:-1920}"
DISPLAY_SIZE="${DISPLAY_SIZE:-${SHOT_W}x${SHOT_H}}"
SHOT_CROP_VERTICAL="${SHOT_CROP_VERTICAL:-center}"

ORIGINAL_WM_SIZE=""
ORIGINAL_WM_DENSITY=""

save_display_profile() {
  ORIGINAL_WM_SIZE="$(adb shell wm size 2>/dev/null | awk '/Physical size/ {print $3}' | tr -d '\r' || true)"
  ORIGINAL_WM_DENSITY="$(adb shell wm density 2>/dev/null | awk '/Physical density/ {print $3}' | tr -d '\r' || true)"
}

set_store_display() {
  save_display_profile
  adb shell wm size "$DISPLAY_SIZE" >/dev/null
  sleep 0.8
}

restore_display_profile() {
  if [[ -n "$ORIGINAL_WM_SIZE" && "$ORIGINAL_WM_SIZE" != "reset" ]]; then
    adb shell wm size "$ORIGINAL_WM_SIZE" >/dev/null 2>&1 || true
  else
    adb shell wm size reset >/dev/null 2>&1 || true
  fi
  if [[ -n "$ORIGINAL_WM_DENSITY" && "$ORIGINAL_WM_DENSITY" != "reset" ]]; then
    adb shell wm density "$ORIGINAL_WM_DENSITY" >/dev/null 2>&1 || true
  else
    adb shell wm density reset >/dev/null 2>&1 || true
  fi
}
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

hide_system_bars() {
  adb shell 'settings put global policy_control immersive.status=*' 2>/dev/null || true
  adb shell 'settings put global policy_control immersive.navigation=*' 2>/dev/null || true
}

restore_system_bars() {
  adb shell 'settings put global policy_control null*' 2>/dev/null || true
}

dump_ui() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 || true
  adb pull /sdcard/ui.xml /tmp/durak-ui.xml >/dev/null 2>&1 || true
}

cap() {
  local out="$1"
  adb shell input keyevent 224 2>/dev/null || true
  sleep 0.35
  adb shell screencap -p /sdcard/_store_cap.png
  adb pull /sdcard/_store_cap.png "$out" >/dev/null
  adb shell rm -f /sdcard/_store_cap.png 2>/dev/null || true
}

tap_by_label() {
  local label="$1"
  dump_ui
  local coords
  coords="$(
    python3 - "$label" <<'PY'
import re, sys
import xml.etree.ElementTree as ET

label = sys.argv[1]
try:
    root = ET.parse("/tmp/durak-ui.xml").getroot()
except (OSError, ET.ParseError):
    sys.exit(0)

bounds_re = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")
for node in root.iter("node"):
    text = node.attrib.get("text", "")
    desc = node.attrib.get("content-desc", "")
    if text != label and desc != label:
        continue
    bounds = node.attrib.get("bounds", "")
    m = bounds_re.search(bounds)
    if not m:
        continue
    x = (int(m.group(1)) + int(m.group(3))) // 2
    y = (int(m.group(2)) + int(m.group(4))) // 2
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

tap_first_playable_card() {
  dump_ui
  local coords
  coords="$(
    python3 - <<'PY'
import re
import xml.etree.ElementTree as ET

ranks = (
    "шестёрка", "семёрка", "восьмёрка", "девятка", "десятка",
    "валет", "дама", "король", "туз",
)
try:
    root = ET.parse("/tmp/durak-ui.xml").getroot()
except (OSError, ET.ParseError):
    sys.exit(0)

bounds_re = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")
best = None
for node in root.iter("node"):
    if node.attrib.get("clickable", "false") != "true":
        continue
    desc = node.attrib.get("content-desc", "")
    if not any(rank in desc for rank in ranks):
        continue
    bounds = node.attrib.get("bounds", "")
    m = bounds_re.search(bounds)
    if not m:
        continue
    x1, y1, x2, y2 = map(int, m.groups())
    y = (y1 + y2) // 2
    if best is None or y > best[1]:
        best = ((x1 + x2) // 2, y)

if best:
    print(f"{best[0]} {best[1]}")
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

strip_system_chrome() {
  local f="$1" top="${STRIP_STATUS_TOP_PX}" bottom="${STRIP_NAV_BOTTOM_PX}" tmp="${f}.strip.tmp.png" w h nh
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "capture_store_screenshots: ffmpeg не найден — system chrome не обрезан: $f" >&2
    return 0
  fi
  w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  nh=$((h - top - bottom))
  if [[ -z "$w" || -z "$h" || "$nh" -lt 32 ]]; then
    echo "capture_store_screenshots: не удалось определить размер: $f" >&2
    return 0
  fi
  ffmpeg -y -nostdin -hide_banner -loglevel error -i "$f" \
    -vf "crop=${w}:${nh}:0:${top},scale=${SHOT_W}:${SHOT_H}" -frames:v 1 "$tmp"
  mv "$tmp" "$f"
}

store_portrait_9x16() {
  local src="$1" dst="$2" w="${SHOT_W}" h="${SHOT_H}" sw sh
  sw=$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  sh=$(sips -g pixelHeight "$src" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  if [[ "$sw" == "$w" && "$sh" == "$h" ]]; then
    cp "$src" "$dst"
    return 0
  fi
  local cy_expr
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

cleanup() {
  restore_system_bars
  restore_display_profile
}
trap cleanup EXIT

adb devices | grep -q emulator || {
  echo "capture_store_screenshots: нет подключённого эмулятора" >&2
  exit 1
}
wait_boot
set_store_display
hide_system_bars
adb shell input keyevent 224 2>/dev/null || true
sleep 0.35

fresh_home
cap "$OUT/01_ru_home.png"

fresh_home
tap_menu "Новая игра" 540 1094
sleep 2.5
cap "$OUT/02_ru_game.png"

fresh_home
tap_menu "Новая игра" 540 1094
sleep 2.5
if tap_first_playable_card; then
  sleep 4
fi
cap "$OUT/03_ru_gameplay.png"

fresh_home
tap_menu "Статистика" 540 1238
sleep 1.5
cap "$OUT/04_ru_statistics.png"

fresh_home
tap_menu "Правила" 540 1381
sleep 1.2
cap "$OUT/05_ru_rules.png"

for f in "$OUT"/0*.png; do
  [[ -f "$f" ]] || continue
  strip_system_chrome "$f"
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
