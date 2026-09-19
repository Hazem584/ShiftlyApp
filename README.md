# Shiftly

Shiftly is a Flutter shift-management app for **Shift Lab**. Sprint 1 delivers the manager-facing mobile foundation with mock, session-only data.

## Sprint 1 features

- Material 3 app using `MaterialApp.router` and `go_router`
- Five-tab manager shell: Dashboard, Employees, Attendance, Requests, and Profile
- Repository-backed dashboard with loading, loaded, empty, and error states
- Searchable employee directory and employee details
- Validated add-employee flow with immediate in-session updates
- Feature-first architecture using repository interfaces and Cubits
- Bundled Cairo variable font under the SIL Open Font License
- Widget and unit coverage for startup, routing, dashboard states, search, form validation, adding employees, repositories, and Cubits

Attendance, Requests, and Profile intentionally show polished placeholders; their full workflows are outside Sprint 1.

## Requirements

- Flutter 3.35 or newer
- Dart 3.13 or newer

## Run locally

```sh
flutter pub get
flutter run
```

The app opens directly in the Manager experience. No backend, authentication, Firebase project, secrets, or environment configuration is required.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Architecture

Shared models and design primitives live under `lib/core`. Each feature owns its data contracts, mock implementations, state, screens, and reusable widgets. Repository interfaces keep widgets independent of the mock data source so a future API implementation can replace it without rebuilding the UI.
