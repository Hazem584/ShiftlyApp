# Shiftly

Flutter app for managing workspaces, shifts, attendance, personal tasks and team chat. Managers handle employee schedules and attendance reviews. Employees track their work, request corrections and communicate with their team. English and Arabic are supported, including RTL layouts and light/dark themes.

## Run locally

Use the Flutter SDK compatible with `pubspec.yaml`, Android Studio or Xcode, and the same Supabase project as Shiftly Backend.

```sh
flutter pub get
```

Copy `config/dev.example.json` to `config/dev.json`. Set `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` and `SHIFTLY_API_BASE_URL`. The API URL ends in `/api/v1`. On the Android emulator, use `10.0.2.2` to reach a local API.

```sh
flutter run --dart-define-from-file=config/dev.json
```

For production, copy `config/prod.example.json` to `config/prod.json` and configure signing and Firebase platform files. Local configuration files contain deployment settings and should stay outside Git.

```sh
flutter build apk --release --dart-define-from-file=config/prod.json
```

For web, configure `config/web.local.json` from `config/web.example.json` and use `flutter build web --dart-define-from-file=config/web.local.json`.

## Code map

| Location | Responsibility |
| --- | --- |
| `lib/main.dart` | Startup and platform initialization |
| `lib/app/app_repositories.dart` | Resolve injected repositories and preview implementations |
| `lib/app/app_composition.dart` | Wire feature controllers and manage their lifecycle |
| `lib/core/di/` | Production dependency registration |
| `lib/core/routing/` | Routes, redirects and navigation |
| `lib/core/session/` | Authentication and active workspace scope |
| `lib/core/theme/` | Theme colors, component styles and appearance preferences |
| `lib/core/localization/` | English keys and Arabic translations |
| `lib/features/` | Feature-specific domain, data, application and presentation code |
| `test/` | Unit, widget and architecture checks |
| `scripts/`, `tool/ci/` | Build preparation and release utilities |

A screen calls a cubit/controller, which uses a domain repository interface. The data implementation talks to the API or local storage. UI code depends on interfaces. Session changes rebind feature state so cached data stays scoped to its account and workspace.

### Find common workflows

- Attendance and monthly calendars live in `features/attendance/`. Correction requests and manager approvals live in `features/team_work/`.
- Scheduling and daily exceptions live in `features/fixed_shifts/`. Reports live in `features/reports/`, with separate screen, table sources and totals widgets.
- Chat history, attachments and the persistent outbox live in `features/chat/`. Private Supabase Realtime events update the view; REST reconciles missed events after reconnecting.
- Personal tasks and Home Screen widgets live in `features/tasks/`. Widget snapshots contain display data and clear on account/workspace changes.

## Make a change

Start in the feature that owns the behavior. Keep business rules in domain/application code and API parsing in data code. Register new dependencies in `core/di/` and connect lifecycle changes in `app/`. Use shared theme styles and translation keys for new UI.

```sh
flutter analyze
flutter test
```

Architecture tests enforce independent domain code and small, focused UI files. Run the relevant feature tests while developing, then the complete suite before release.

## Release integrations

Push notifications need Firebase configuration and signing. Alternate icons are prepared with `node scripts/prepare-app-icons.mjs --defines config/prod.json` before building. Uploaded images become selectable on devices after a release bundles them.

For iOS task widgets, configure the Runner and TaskWidget App Group entitlements in Xcode. The current shared group is `group.com.example.shiftly`. Keep the group and bundle identifiers aligned when changing signing settings.

Companion projects are **ShiftlyBackend** (NestJS API) and **Shiftly-Admin** (React platform dashboard). Database migrations are deployed from the backend repository before clients that require them.
