# Shiftly

Shiftly is a Flutter workforce management app for managers and employees. It brings workspaces, shifts, attendance, tasks, team chat, team updates into one place, with English and Arabic support.

## Requirements

- Flutter with Dart 3.13 or newer, compatible with `pubspec.yaml`.
- Android Studio or Xcode for mobile builds; Xcode requires macOS.
- A configured Supabase project and the running Shiftly backend.
- Node.js 24 when preparing alternate app icons.

## Setup

```sh
flutter pub get
```

Copy `config/dev.example.json` to `config/dev.json` and fill in:

- `SUPABASE_URL`: your Supabase project URL.
- `SUPABASE_PUBLISHABLE_KEY`: the public client key.
- `SHIFTLY_API_BASE_URL`: the backend URL ending in `/api/v1`.

Keep local configuration private. Use the same Supabase project as the backend and admin dashboard. For an Android emulator, use `10.0.2.2` instead of `localhost` to reach a local backend.

```sh
flutter run --dart-define-from-file=config/dev.json
```

## Build and check

Copy `config/prod.example.json` to `config/prod.json` and set the production values before building.

```sh
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/prod.json
```

For web, use `flutter build web --dart-define-from-file=config/web.local.json` after copying and configuring `config/web.example.json`. Configure Firebase platform files and Android signing separately for push notifications and release distribution.

Alternate launcher icons must be bundled before release:

```sh
node scripts/prepare-app-icons.mjs --defines config/prod.json
```

## Project structure

- `lib/features/`: feature modules with domain, data, and presentation layers.
- `lib/core/`: shared configuration, authentication, navigation, and UI.
- `assets/`: bundled fonts and images.
- `test/`: automated tests.
- `scripts/` and `tool/ci/`: build and release utilities.

The companion projects are **ShiftlyBackend** (NestJS API) and **Shiftly-Admin** (React platform dashboard). Optional screenshot capture tests write to the ignored `.artifacts/ui-review/` directory.

## Live chat

Chat uses private Supabase Realtime Broadcast channels with REST reconciliation after reconnecting. Messages and reactions render directly from authorized events; cached history and a persistent outbox keep conversations usable during transient connection failures. Conversation summaries are cached for seven days, message history for thirty days, and downloaded media for fourteen days, subject to storage limits and account access.

Supported document attachments: PDF, Excel (.xlsx/.xls), CSV, and plain text, up to 10 MiB per file. Use Attach → Document. Long-press a message or open its actions to add, change, or remove a reaction. Document downloads reuse the private media cache; use Save or share document to export a copy.

Deploy the matching backend migration before releasing this client. Supabase Realtime must be enabled for the project; the migration sets up private-channel authorization and publication entries. Changes are not deployed automatically. Test with two signed-in devices, including reconnecting, removing a member, and revoking a session, before production release.

## Home screen task widget

Android and iOS widgets show the remaining **personal tasks** count, up to three task titles, and native countdowns. Tap a task to open its details. On Android, use the widget button in Task manager or long-press the Home Screen and select Widgets → Shiftly tasks. On iOS, add Shiftly tasks from the Home Screen widget gallery.

The app shares a local display snapshot when tasks refresh or change and when it resumes. Countdowns and scheduled occurrences advance locally; changes made on another device are fetched the next time this app refreshes. The widget shows its last update time, expires snapshots after 24 hours, and clears data on sign-out or account/workspace changes. It does not store authentication tokens or fetch the API in the background.

For iOS signing, enable the **App Groups** capability for Runner and TaskWidget and register `group.com.example.shiftly` in the same Apple team. If the application bundle identifier changes, update both targets' group entitlements and the suite names in AppDelegate.swift and TaskWidget.swift. The WidgetKit target is included and embedded in the Xcode project. Build and test the iOS target on macOS/Xcode.
