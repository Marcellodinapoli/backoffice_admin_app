#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CACHE_ROOT="${NETLIFY_BUILD_CACHE:-${NETLIFY_BUILD_BASE:-$HOME}/.netlify_cache}"
FLUTTER_DIR="${CACHE_ROOT}/flutter"
export PUB_CACHE="${CACHE_ROOT}/pub-cache"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

echo "==> Netlify build BackOffice Admin App (Flutter web)"
echo "    Root: $ROOT"

if [[ ! -f "$FLUTTER_DIR/bin/flutter" ]]; then
  echo "==> Install Flutter ($FLUTTER_CHANNEL)..."
  rm -rf "$FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get
flutter build web --release

if [[ ! -f "$ROOT/build/web/index.html" ]]; then
  echo "ERRORE: build/web/index.html mancante"
  exit 1
fi

echo "==> Build OK: $ROOT/build/web"
