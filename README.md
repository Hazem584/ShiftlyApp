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
