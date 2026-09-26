# Shiftly

Shiftly is a Flutter workforce app backed by Supabase Auth and the Shiftly NestJS API. The current sprint connects identity, profile bootstrap, workspace membership, and role-based routing while keeping feature screens on their existing mock repositories.

## Configuration

The app requires three compile-time Dart defines:

- `SUPABASE_URL`: the HTTPS URL of the Supabase project.
- `SUPABASE_PUBLISHABLE_KEY`: the client-safe publishable/anon key. Never use a service-role key.
- `SHIFTLY_API_BASE_URL`: the complete API prefix, ending exactly once in `/api/v1`.

Use placeholders locally:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=SHIFTLY_API_BASE_URL=https://shiftly-backend-gamma.vercel.app/api/v1
```

Or copy `config/dev.example.json` to an ignored file such as `config/dev.json` and run:

```sh
flutter run --dart-define-from-file=config/dev.json
```

Production example:

```sh
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=SHIFTLY_API_BASE_URL=https://shiftly-backend-gamma.vercel.app/api/v1
```

Configuration is validated before the app starts. Supabase must use HTTPS. The API may use HTTP only for `localhost`, `127.0.0.1`, or the Android emulator host `10.0.2.2`; deployed endpoints must use HTTPS. Query strings, fragments, missing values, and duplicated API prefixes are rejected with a developer-facing configuration screen. Values and keys are never logged.

## Authentication and sessions

Supabase owns access-token and refresh-token persistence. Shiftly does not copy either token into app storage. Sign-in uses email/password through the Supabase SDK, then `GET /auth/me` validates the restored session and loads the backend profile and active memberships. A missing backend profile routes to profile setup, which sends only `fullName` and optional `phone` to `POST /auth/bootstrap` before reloading `/auth/me`.

The Dio client reads the latest Supabase session for each protected request and sends its bearer token only to the configured Shiftly API host and `/api/v1` path. A `401` starts one shared Supabase refresh operation; concurrent failures await it, and each request is retried at most once with its original method, path, query, body, and cancellation token. Failed refresh clears the selected workspace, signs out locally, and returns to login. `403` and `404` are never treated as refresh failures.

## Role and workspace routing

The backend is the only authority for roles and membership status. The app ignores inactive and unknown memberships:

- One active membership is selected automatically.
- Multiple active memberships restore `activeWorkspaceId` only when it still appears in the fresh response; otherwise the workspace chooser is shown.
- No active memberships show a retryable no-workspace state.
- `MANAGER` routes to the existing manager shell; `EMPLOYEE` routes to the employee shell.

Only `activeWorkspaceId` is stored in SharedPreferences. Roles and tokens are not stored there. Deep links remain behind session resolution, and logout clears protected navigation history through router redirects.

## Errors and offline behavior

Backend error envelopes, validation arrays, plain-text proxy failures, timeouts, cancellation, connection failures, and common HTTP statuses are converted to safe user messages. The backend `requestId` remains attached to the typed exception for support diagnostics. A backend outage with a locally restored Supabase session shows an offline/retry state; it never grants a manager or employee route from cached data.

## Architecture

The app retains its feature-first structure, repository injection, Cubits, GoRouter, theme, and custom toast. Shared integration code lives under `lib/core/config`, `error`, `network`, `session`, and `storage`. Authentication owns its service wrapper, API repository, models, screens, and focused widgets under `lib/features/auth`.

## Verification

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

Automated tests use fakes and an in-memory Dio adapter; they never call production Supabase or Vercel.

## Still mocked

Dashboard cards, employee management, shifts, attendance, leave requests, notifications, profile editing/avatar upload, and other feature data still use presentation mocks. The next sprint can replace those repositories with workspace-scoped NestJS implementations. No Flutter code reads Supabase application tables directly.
