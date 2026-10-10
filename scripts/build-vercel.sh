#!/usr/bin/env bash
set -euo pipefail

# Keep this SDK aligned with CI and the Dart constraint in pubspec.yaml.
FLUTTER_VERSION="3.47.6"
SDK_DIRECTORY="${VERCEL_CACHE_DIR:-.vercel/cache}/flutter-${FLUTTER_VERSION}"
if [[ ! -x "${SDK_DIRECTORY}/bin/flutter" ]]; then
  mkdir -p "$(dirname "${SDK_DIRECTORY}")"
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${SDK_DIRECTORY}"
fi
export PATH="$(cd "${SDK_DIRECTORY}" && pwd)/bin:${PATH}"
export CI=true
flutter config --no-analytics --enable-web

DEFINE_FILE="$(mktemp)"
trap 'rm -f "${DEFINE_FILE}"' EXIT
node scripts/write-web-config.cjs "${DEFINE_FILE}"
flutter pub get
flutter build web --release --no-pub --no-wasm-dry-run --dart-define-from-file="${DEFINE_FILE}"
