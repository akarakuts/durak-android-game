#!/usr/bin/env bash
# Растровые mipmap из design/app-icon.svg (RuStore 512 + legacy PNG).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/design/app-icon.svg"
RES="$ROOT/android/app/src/main/res"
STORE="$ROOT/docs/rustore/ic_launcher_store_512.png"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "generate_launcher_icons: требуется rsvg-convert (brew install librsvg)" >&2
  exit 1
fi

mkdir -p "$(dirname "$STORE")"
rsvg-convert -w 512 -h 512 "$SVG" -o "$STORE"

while read -r density size; do
  dir="$RES/mipmap-$density"
  mkdir -p "$dir"
  rsvg-convert -w "$size" -h "$size" "$SVG" -o "$dir/ic_launcher.png"
  cp -f "$dir/ic_launcher.png" "$dir/ic_launcher_round.png"
done <<'EOF'
mdpi 48
hdpi 72
xhdpi 96
xxhdpi 144
xxxhdpi 192
EOF

echo "Launcher icons generated from $SVG"
