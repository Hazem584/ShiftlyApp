# Builds small, per-device Android release artifacts.
# A universal APK bundles native code for every CPU type (~3x bigger),
# so we ship one APK per ABI and an App Bundle for Google Play.
param([string]$Config = "config/prod.json")

$common = @(
  "--release",
  "--dart-define-from-file=$Config",
  "--obfuscate",
  "--split-debug-info=build/symbols",
  "--tree-shake-icons"
)

flutter build apk @common --split-per-abi
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build appbundle @common
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Get-ChildItem build/app/outputs/flutter-apk/*-release.apk, build/app/outputs/bundle/release/*.aab |
  ForEach-Object { "{0,7:N1} MB  {1}" -f ($_.Length / 1MB), $_.Name }
