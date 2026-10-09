# Shiftly branding, splash, and onboarding handoff

Initial HEAD: `d448a2c5647f08d009cd7942fcc1a65e02dfb6a2`. Initial worktree: clean.
Approved source: `assets/images/Logo.png`, inspected visually and as 1254×1254
opaque RGB. Source artwork is unchanged.

No branding dependency additions. Installed Dart cache reports 3.13.5, compatible with the
existing `^3.13.0` constraint. Existing GetIt, Bloc/Cubit, GoRouter, SharedPreferences,
theme colors, Cairo font, application IDs, signing, and Firebase workflow are retained.

The PowerShell generator and JSON configuration reproduce the native PNGs and Android
XML/color resources. iOS uses the existing asset catalog slots and an updated static
LaunchScreen storyboard, with named light/dark colors. Generated image dimensions,
opaque iOS pixel formats, native XML, and the adaptive foreground were inspected.
No APK/native build was run. iOS behavior requires Xcode/device verification; Android
OS masks/launch transitions also require device checks. No recolored monochrome icon
was fabricated from the flattened source.

Onboarding has separate persistence, content, state/cubit, screen, illustration, and
indicator files. The existing router refresh observes its state alongside the existing
SessionCoordinator. Session loading remains authoritative; authenticated roles and
profile/workspace/offline/expired paths take precedence. Completion is persisted before
navigation; failures and duplicate taps are guarded. The versioned preference is
independent of tokens/workspaces and is not cleared on logout. Authenticated bypass is
remembered for the process without falsely writing a completion flag.

Tests cover preference restoration/isolation, failed read/write and retries, duplicate
completion, delayed first launch without a login flash, Skip/Get Started, all three
pages, validated role bypass/logout, auth change while visible, profile/workspace/offline
and expiry regressions, compact 320px/2× light/dark layouts, reduced motion, logo loading,
and readable session loading.

README contains generation commands, official platform
references, limitations, and the manual clean-install/restart/Skip/Get Started/auth/logout/
dark/compact-screen sequence.

Backend, database, migrations, deployment, Git history, application IDs, signing, and
Firebase CI were not changed. No APK builds, backend commands, or `git diff --check`.

Continuation inspection: the branding implementation and generated assets were already
present and were preserved. The previous formatter tool request returned `aborted`,
without command output or an exit result; the new Dart files were still unformatted.
No branding analyze/test execution was recorded before continuation. Existing chat/clock
verification logs belong to earlier work and were not rerun.

Unrelated dependency resolution changes in `pubspec.lock`,
`linux/flutter/generated_plugin_registrant.cc`, and
`linux/flutter/generated_plugins.cmake` were found on continuation and preserved.
They update existing dependencies/plugin registrations; branding adds no package.
The required whole-tree formatter also changed whitespace in
`lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart` and
`test/fixed_shifts_sprint_test.dart`; their behavior/assertions were not changed.

Final checks (one execution each after continuation):

- `dart format .`: exit 0; 669 files processed, 20 changed, 5.20 seconds.
- `flutter analyze`: exit 0; No issues found, 5.5 seconds.
- `flutter test`: exit 1 after interruption with Ctrl+C. Last reported count was
  436 passed, 1 failed; the remaining suite did not complete. The original execution
  stopped producing output at the existing legacy clock-in widget test and remained
  stalled beyond the SDK's documented ten-minute widget-test timeout. This is an
  incomplete failed run, not a passing suite.

The original test execution reported a pending 350 ms timer in
`validated WorkspaceRole.manager session bypasses onboarding and logout preserves completion`.
The preview fixture now explicitly injects `MockEmployeeRepository(delay: Duration.zero)`
for the application's employee repository as well as the dashboard fixture. Assertions
and production behavior are unchanged. This test-only correction was made after format
and analysis and after that test executed; it has not been formatted/analyzed/tested
by another command. No verification rerun is claimed.

The stalled existing test was
`ambiguous legacy intent shows review and refresh without a replay action` in
`test/fixed_shifts_sprint_test.dart`. Its `bindSession` started a Dio load under the
simulated test clock before `runAsync(cubit.load)` joined that in-flight load. The
fixture now starts `bindSession` and awaits `load` within the same `runAsync` callback.
All review/replay/GET-only assertions are retained. This second test-only correction
is also unverified after the final checks. No production Dart changes followed analysis.

Changed-file manifest (native density/scale families grouped):

- `README.md`, `docs/flutter-branding-sprint.md`, `pubspec.yaml`.
- `tool/branding.json`, `tool/generate-branding.ps1`.
- `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`.
- `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/`:
  `ic_launcher_foreground.png`, `shiftly_splash.png`, `shiftly_splash_android12.png`.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`.
- `android/app/src/main/res/drawable/launch_background.xml` and
  `drawable-v21/launch_background.xml`.
- `android/app/src/main/res/{values,values-night}/`: `styles.xml`, `branding_colors.xml`.
- `android/app/src/main/res/{values-v31,values-night-v31}/styles.xml`.
- All 15 existing PNG slots in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`,
  `LaunchImage@2x.png`, `LaunchImage@3x.png`.
- `ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json`.
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`.
- `lib/app/app_providers.dart`, `lib/app/shiftly_app.dart`.
- `lib/app/parts/app_providers/private_app_providers_state.dart`,
  `private_session_router_refresh.dart`.
- `lib/core/di/dependency_registration.dart`, `lib/core/routing/app_router.dart`.
- `lib/core/widgets/brand_logo.dart`, `brand_session_loading.dart`.
- `lib/features/auth/presentation/screens/session_status_screen.dart` and
  `parts/session_status_screen/session_status_screen.dart`.
- `lib/features/onboarding/data/onboarding_storage.dart`,
  `preferences_onboarding_storage.dart`, `memory_onboarding_storage.dart`.
- `lib/features/onboarding/domain/onboarding_page_content.dart`.
- `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart`, `onboarding_state.dart`.
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`.
- `lib/features/onboarding/presentation/widgets/onboarding_illustration.dart`,
  `onboarding_page_indicator.dart`.
- `test/onboarding_test.dart`, `test/support/onboarding_test_auth.dart`,
  `onboarding_test_repository.dart`, `onboarding_test_storage.dart`.
- Preserved unrelated/formatting-only files listed above.
