#!/usr/bin/env bash
set -euo pipefail

# Match the verified Linux release used by firebase-app-distribution.yml.
FLUTTER_VERSION="3.47.6"
FRAMEWORK_REVISION="5fc346839b5d0eef006ed8404392afb4dfae428d"
DART_VERSION="3.13.5"
ARCHIVE_SHA256="f1631b9c2c8b3529323db412b0d1beacf4a748f8783b0d7cf599a8fd5f461675"

BUILD_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/shiftly-web-build.XXXXXX")"
trap 'rm -rf -- "${BUILD_TEMP}"' EXIT
DEFINE_FILE="${BUILD_TEMP}/web-config.json"
# Validate public settings before spending time downloading the SDK.
node scripts/write-web-config.cjs "${DEFINE_FILE}"

# Do not restore an SDK checkout from Vercel's cache. Its Git metadata may be
# missing, causing Flutter to resolve engine artifacts from the app repository.
ARCHIVE="${BUILD_TEMP}/flutter-sdk.tar.xz"
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
  --output "${ARCHIVE}"
printf '%s  %s\n' "${ARCHIVE_SHA256}" "${ARCHIVE}" | sha256sum --check --strict
tar -xJf "${ARCHIVE}" -C "${BUILD_TEMP}"
rm -- "${ARCHIVE}"

SDK_DIRECTORY="${BUILD_TEMP}/flutter"
export PATH="${SDK_DIRECTORY}/bin:${PATH}"
export CI=true
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE FLUTTER_REALM
export FLUTTER_PREBUILT_ENGINE_VERSION="$(< "${SDK_DIRECTORY}/bin/internal/engine.version")"
flutter --version --machine > "${BUILD_TEMP}/flutter-version.json"
node - "${BUILD_TEMP}/flutter-version.json" "${FLUTTER_VERSION}" "${FRAMEWORK_REVISION}" "${DART_VERSION}" <<'NODE'
const fs = require('node:fs');
const [file, release, revision, dart] = process.argv.slice(2);
const version = JSON.parse(fs.readFileSync(file, 'utf8'));
if (version.frameworkVersion !== release || version.channel !== 'stable' ||
    version.frameworkRevision !== revision || version.dartSdkVersion?.split(' ')[0] !== dart) {
  throw new Error('Flutter SDK verification failed: release metadata does not match the pinned SDK.');
}
console.log(`Verified Flutter ${release} stable / Dart ${dart}`);
NODE
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --no-pub --no-wasm-dry-run --dart-define-from-file="${DEFINE_FILE}"
