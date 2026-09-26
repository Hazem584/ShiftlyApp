# Shiftly

Shiftly is a Flutter workforce app backed by Supabase Auth and the Shiftly NestJS API. Authentication, profile editing, avatar management, workspace membership, and role-based routing use the production API while unrelated feature screens retain their mock repositories.

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

### Supabase Dashboard setup for development

- Enable the Email password provider under Authentication providers.
- Decide whether Confirm email is enabled for the development project. The app supports both immediate-session and confirmation-required sign-up results.
- Set the Site URL to the browser destination used by the project. This sprint does not add Android/iOS universal or app links, so a browser confirmation may not reopen Shiftly automatically.
- On an Android emulator, register with a non-production test address, open its inbox in the host browser or emulator browser, follow the confirmation link, return to Shiftly, and use **Back to sign in**. Then sign in with the verified account.
- Only `SUPABASE_URL` and the client-safe publishable/anon key belong in Flutter. Never add a service-role key.
- Email delivery customization and universal/app-link integration are outside this sprint.

## Authentication and sessions

Supabase owns access-token and refresh-token persistence. Shiftly does not copy either token into app storage. Sign-in uses email/password through the Supabase SDK, then `GET /auth/me` validates the restored session and loads the backend profile and active memberships. A missing backend profile routes to profile setup, which sends only `fullName` and optional `phone` to `POST /auth/bootstrap` before reloading `/auth/me`.

Account creation uses the same Supabase client and asks only for email, password, and password confirmation. It never asks the user to choose a role. If Supabase returns a session immediately, backend profile and workspace resolution starts immediately. If email confirmation is enabled, the app shows the normalized address, supports a guarded resend action, and does not contact protected NestJS endpoints until Supabase supplies a session. No password is retained outside the screen controllers.

The current invitation onboarding flow is:

```text
Manager creates invitation
-> manager securely shares one-time token
-> employee creates account with the exact invited email
-> employee verifies email
-> employee logs in
-> employee completes profile setup
-> employee views pending invitation
-> employee pastes token
-> backend accepts invitation
-> Flutter refreshes /auth/me
-> employee enters Employee shell
```

The pending-invitations response deliberately does not contain the one-time token. Managers must share it manually and securely in this sprint. Flutter trims it only at submission, never logs or persists it, and treats the acceptance response as provisional until a fresh `/auth/me` confirms an active known-role membership for the same user and workspace.

The deployed backend must support the nullable-phone contract separately before clients can explicitly clear a saved phone with `null`. Profile bootstrap omits blank optional phone values and never invents a placeholder.

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

Dashboard cards, employee management, shifts, attendance, leave requests, notifications, and other non-profile feature data still use presentation mocks. Profile JSON and avatar mutations go only through NestJS; Flutter never writes directly to Supabase Storage or application tables. The mock profile repository remains available only for isolated tests and previews.
