# Shiftly

Shiftly is a Flutter workforce app backed by Supabase Auth and the Shiftly NestJS API. Authenticated startup uses production repositories for every feature; preview and test repositories are selected only by explicit composition.

## Android tester distribution

[Firebase App Distribution](.github/workflows/firebase-app-distribution.yml) builds a
single signed release APK from the event commit on every push to **`Master`**
(case-sensitive). Manual runs also require `Master`. PRs and forks cannot distribute.
Runs share one lock; stale commits are skipped immediately before uploading. GitHub
may replace a pending run with a newer pending run during rapid pushes, so superseded
commits are not guaranteed a distribution.

CI pins Flutter **3.47.6** (Dart **3.13.5**, official Linux x64 SDK archive), Temurin
**17.0.14+7**, Node **22.14.0**, and Firebase CLI **14.22.0**. Actions are pinned to
reviewed release commit SHAs. These match the Dart `^3.13.0` constraint and lockfile's
Flutter `>=3.47.0`; the existing AGP **9.1.0** / Gradle **9.3.1** setup requires Java
17. Existing Gradle compatibility flags and Kotlin configuration are preserved.
See [AGP compatibility](https://developer.android.com/build/releases/agp-9-1-0-release-notes)
and [Firebase CLI distribution](https://firebase.google.com/docs/app-distribution/android/distribute-cli).

The SDK archive is checked against its published SHA-256 before extraction, and
`flutter --version --machine` must report the pinned release, stable channel,
framework revision, and Dart version before `pub get`. The archive's release
metadata is preserved. CI discards the old shallow-checkout installation and uses
a fresh extraction without restoring or saving an SDK cache; an unknown version
fails immediately instead of changing dependency constraints.

Release builds capture verbose output in a private temporary log. On failure,
`tool/ci/summarize_release_failure.py` reports known failed Flutter targets and
Gradle tasks, allowlisted error signatures and exception types, subprocess exit
codes, compiler switches, compiler/tool stack frames, and reported app source
locations. A frontend invocation alone does not prove a compiler crash. Unknown
exception messages remain private; absence of a signature does not rule out that
failure. Paths, positional arguments, Dart
defines (including encoded values), and option values are redacted. The raw log
is deleted with the other private inputs and is never uploaded as an artifact.
If a frontend crash has no source location, use the redacted invocation and stack
to construct a minimal reproduction with placeholder configuration for an upstream
Dart report; do not infer an offending plugin from a preceding Gradle warning.

Repository **Settings → Secrets and variables → Actions** must contain:

| Type | Name | Value format |
| --- | --- | --- |
| Variable | `FIREBASE_ANDROID_APP_ID` | Firebase Android App ID, for the registered package `com.example.shiftly` |
| Variable | `FIREBASE_TESTER_GROUPS` | Comma-separated Firebase tester **group aliases**, with testers added |
| Secret | `FIREBASE_SERVICE_ACCOUNT_JSON` | Complete service-account key JSON; account has Firebase App Distribution Admin (`roles/firebaseappdistro.admin`) on the testing project |
| Secret | `SHIFTLY_DART_DEFINES_JSON` | JSON object with `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `SHIFTLY_API_BASE_URL`; use the testing environment and a client-safe Supabase key |
| Secret | `ANDROID_KEYSTORE_BASE64` | Base64 of the existing release keystore; wrapped base64 is supported |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| Secret | `ANDROID_KEY_ALIAS` | `shiftly` |
| Secret | `ANDROID_KEY_PASSWORD` | Password for the `shiftly` key |

For the first run, confirm App Distribution is enabled for the Firebase testing
Android app and that the configured groups have testers. Registering that app is
sufficient: no Firebase runtime SDK or `google-services.json` is required. Keep the
same signing key for all updates.

Review and commit the workflow, Gradle signing change, README, and `.gitignore` to
`Master`, then push with `git push origin Master`. In GitHub **Actions → Firebase App
Distribution**, open the push run. To start a manual run, choose **Run workflow →
Branch: Master → Run workflow**. The workflow must be on the repository's default
branch before GitHub exposes manual dispatch. Each run resolves dependencies,
analyzes, and tests once; any failure stops the build and upload. Firebase release
notes record the branch, exact commit SHA, and commit subject.

Testers accept their Firebase email invitation with the invited Google account,
open the release in Firebase App Tester, and download/install the APK. Android may
ask them to allow installation from that source. An existing debug-signed install
must be uninstalled before installing the release-signed app; this removes its local
data. Later releases signed with the same key install as updates.

CI versionCode is UTC seconds since 2020-01-01, computed inside the serialized job.
It advances on reruns, including reruns of older workflow runs, and must exceed the
current `pubspec.yaml` code (currently `1`) while staying at or below Android's
`2100000000` limit. Builds take longer than one second; this scheme is bounded until
2086 and fails rather than wrapping. An old commit rerun cannot upload after `Master`
advances. Do not independently publish higher versionCodes for this testing app
without updating this scheme.

Troubleshooting: missing/invalid inputs fail by name without logging their values.
Signing failures require checking the keystore, passwords, and `shiftly` alias in
GitHub settings; release builds never fall back to debug signing. Local debug builds
continue to work without signing variables. Local release builds now require
`ANDROID_KEYSTORE_PATH` plus the three signing password/alias environment variables.
Dependency, analysis, or test failures must be fixed before distribution. For Firebase
upload failures, check the testing app ID/package, IAM role, group aliases, App
Distribution setup, and service status. Firebase output is deliberately withheld
because it contains signed download URLs; inspect releases in the Firebase console.
Temporary configuration, credentials, keystore, and Firebase logs are deleted by an
`always()` cleanup step, including on failures. Hosted runner teardown covers abrupt
runner termination. No credentials or APKs are uploaded as GitHub artifacts.

## App configuration

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

The project is feature-first. `lib/app` owns the root widget, application providers, lifecycle binding, and session-to-feature coordination. `lib/core` owns configuration, DI, errors, the single authenticated network client, routing, session, storage, theme, shared widgets, and genuinely cross-feature utilities. Each `lib/features/<feature>` tree keeps its data contracts and implementations beside its presentation Cubits, screens, and widgets; domain folders are added only where a feature has a real UI-independent domain abstraction.

`lib/core/di/dependency_registration.dart` is the production composition root. `AppConfig`, the Supabase client, SharedPreferences, and established instances are singletons. The authenticated `ApiClient`/Dio client, `SessionCoordinator`, repository abstractions, upload adapter, media Realtime source, and safe application services are lazy singletons. Fresh presentation Cubits are factories; the owning `BlocProvider` or application provider tree closes them. Locator access is confined to startup and provider/screen composition boundaries—repositories, models, and Cubit business logic continue to use constructor injection.

Production calls `DependencyRegistration.configureProduction()` and fails before authenticated UI construction if configuration or a required registration is missing. It never chooses mocks based on debug/release mode. Tests can create an isolated `GetIt.asNewInstance()`, call `configureTestDependencies` with explicit fakes, and call `DependencyDisposal.reset(locator: testLocator)` in teardown. Component tests use the explicit `ShiftlyApp.preview` constructor; preview composition is not reachable from production `main.dart`.

Session-bound Cubits receive a `FeatureSessionScope`. `SessionFeatureCoordinator` changes its generation only when user, workspace, membership, role, membership access, login/logout, or explicit invalidation changes the data/security scope. Token refreshes and equivalent profile/session emissions keep the generation stable. Screen Cubits are never shared globally; application Cubits are created once per `AppProviders` owner and closed there. GetIt singletons are disposed only by `DependencyDisposal`.

New features should keep transport parsing and API implementations in `data`, UI-independent entities/repository interfaces in `domain` only when useful, and Cubits/screens/widgets in `presentation`. UI code must not parse JSON or depend directly on Dio, Supabase, or SharedPreferences. Register production abstractions against implementations, add a factory for screen-owned Cubits, provide explicit test replacements, and keep dependencies directed through constructors.

Each meaningful public class, enum, interface, state, model, and controller has its own source file. Compatibility library files use export/`part` directives so existing imports remain stable while declarations live in focused files. Small private widget/state pairs and private implementation records used only by their owning file are the documented exception; generated files are never manually split.

Backend timestamps are parsed and stored as UTC. UI entry and display use the active workspace's IANA timezone through the maintained `timezone` package; device-local time is never treated as the workspace timezone or used as an official attendance timestamp.

## Manual shifts and attendance regression

Use two non-production accounts and an API client such as ApiDog against the same test environment. Do not change device time to bypass backend clock rules.

1. Log in as a manager.
2. Select a workspace.
3. Confirm the target employee has an active membership.
4. Create a shift for that employee and confirm the request uses the employee membership ID.
5. Open the returned shift details.
6. Log out, then log in as the employee.
7. Select the invited workspace.
8. Confirm the assigned shift appears under **My Shifts**.
9. Open the shift details.
10. Attempt an invalid early Clock-in and confirm only the safe backend error is shown.
11. At an allowed time, Clock in and confirm the displayed timestamp is the server-confirmed value.
12. Log in as the manager and open **Attendance**; confirm the pending attendance request appears.
13. Open the attendance details.
14. Approve it, or reject it with a valid rejection reason, and confirm the pending row disappears only after success.
15. Log in as the employee and refresh **Attendance**; confirm the canonical review state appears.
16. Clock out when the backend permits it.
17. Confirm the employee history shows the server-confirmed Clock-in and Clock-out values.
18. Confirm the manager sees the final attendance record.
19. Switch workspaces and confirm the previous workspace's shifts and attendance disappear before the new load completes.
20. Log out User A and log in as User B without restarting the app.
21. Confirm no shifts or attendance from User A appear.

ApiDog checks should use the same endpoint order where useful: create/list/detail shift, employee shift list/detail, rejected early Clock-in, successful Clock-in, pending attendance list/detail/review, employee attendance list, successful Clock-out, and final manager attendance list. Verify methods, IDs, UTC ISO-8601 bodies, pagination envelopes, canonical mutation responses, and `requestId` on deliberate failures.

## Manual leave and multi-workspace regression

Use two non-production accounts and ApiDog against the same test environment.

1. Log in as a manager and select a workspace.
2. Confirm the employee has an active membership in that workspace.
3. Log in as the employee and select the same workspace.
4. Open **Attendance & Leave**, choose **Leave**, and create a valid request.
5. Confirm the canonical response appears as **Pending**.
6. Log in as the manager and open **Attendance → Leave Requests**.
7. Confirm the request appears only in the selected workspace.
8. Approve the request and confirm the row changes only after the API succeeds.
9. Refresh as the employee and confirm **Approved** appears.
10. Create another employee request.
11. Reject it as the manager with a non-empty reason.
12. Refresh as the employee and confirm **Rejected** and the canonical reason appear.
13. Create a pending request and cancel it as the employee.
14. Attempt the cancellation again in ApiDog; confirm the backend safely rejects it as already cancelled/not pending according to its contract.
15. Switch workspaces and confirm old leave, shift, and attendance data clears immediately.
16. Log out User A and log in as User B without restarting; confirm no User A data appears.
17. Create enough records for multiple pages and verify load-more results contain only the selected workspace.
18. Exercise offline, timeout, validation, unauthorized, and already-reviewed responses; confirm retained lists and safe messages.
19. In ApiDog, verify create/list/detail/cancel employee leave routes and list/detail/review manager routes, including pagination, UTC values, error codes, and `requestId`.
20. With one employee active in two workspaces, call `/shifts/me`, `/attendance/me`, and `/leave-requests/me` using each `workspaceId`; verify page totals and every returned row belong only to that workspace.

## Manual notifications regression

Use two non-production accounts in the same workspace. Existing backend shift, attendance, and leave mutations create notifications automatically; there is no public create-notification endpoint. ApiDog should call the business endpoint that produces each event, then inspect the recipient's notification endpoints with that recipient's temporary token.

1. Log in as the manager, select the test workspace, and note the notification badge.
2. Log in as the employee in a separate test session and note the employee badge.
3. In ApiDog, call `GET /api/v1/notifications/unread-count` as each account and compare the global count with its Flutter badge.
4. Create a shift as the manager; confirm the employee receives `SHIFT_ASSIGNED` with `shiftId` and `employeeMembershipId`.
5. Update that shift; confirm the employee receives `SHIFT_UPDATED` with the same payload keys.
6. Cancel a scheduled test shift; confirm the employee receives `SHIFT_CANCELLED`.
7. Clock in as the employee; confirm active managers receive `ATTENDANCE_CLOCKED_IN` with `attendanceId` and `employeeMembershipId`.
8. Clock out as the employee; confirm active managers receive `ATTENDANCE_CLOCKED_OUT` with the same payload keys.
9. Create leave as the employee; confirm active managers receive `LEAVE_REQUEST_CREATED` with `leaveRequestId` and `employeeMembershipId`.
10. Approve a leave request; confirm the employee receives `LEAVE_REQUEST_APPROVED` with `leaveRequestId` and `reviewedByMembershipId`.
11. Reject another request; confirm `LEAVE_REQUEST_REJECTED` also carries the canonical `rejectionReason`.
12. Open an unread Flutter notification; confirm `PATCH /api/v1/notifications/{notificationId}/read` succeeds, the row changes style, and the badge refreshes.
13. Use **Mark all read**; confirm `PATCH /api/v1/notifications/read-all` sends the active `workspaceId`, reloads canonical rows, and refreshes the global badge.
14. Delete a test notification after confirmation; verify `DELETE /api/v1/notifications/{notificationId}` returns `{ "deleted": true }` before the row disappears.
15. Generate more than 20 records and verify `GET /api/v1/notifications?page=2&limit=20&workspaceId=...` and Flutter **Load more** deduplicate rows.
16. Pull to refresh and confirm existing rows remain visible if the refresh is deliberately failed.
17. Open a known notification and confirm it verifies the canonical destination, then routes to Shifts, Attendance, or Leave for the current role.
18. Seed an unknown notification type only in an isolated non-production fixture; confirm neutral presentation, read/delete support, and no navigation.
19. Test a malformed payload ID and a deleted target; confirm Flutter stays on Notifications and shows a safe unavailable message.
20. Switch workspaces; confirm the old list clears immediately and only the selected workspace's rows load. The unread-count endpoint is global by backend contract, so the badge may include other workspaces.
21. Log out User A and log in as User B without restarting; confirm no User A rows appear.
22. Exercise offline, timeout, final `401`, `403`, `404`, `429`, and `502` responses; verify safe messages, retained rows where applicable, and sign-out only after the existing refresh pipeline confirms session expiry.

## Dashboard real-data integration

Production injects `ApiDashboardRepository` with the shared authenticated Dio client. `DashboardCubit` binds to the authenticated user, active workspace, membership, role, and session generation. Manager data comes from `GET /api/v1/workspaces/{workspaceId}/dashboard`; employee data comes from `GET /api/v1/dashboard/me?workspaceId=...`. The app deliberately omits `date`, allowing the backend to define today from the workspace IANA timezone.

Manager UI mapping is exact: Total employees → `summary.totalEmployees`; Scheduled today → `summary.scheduledToday`; Clocked in now → `summary.clockedInNow`; Completed today → `summary.completedToday`; Late → `summary.lateToday`; Missed → `summary.missedToday`; On approved leave → `summary.onApprovedLeave`; pending badges/cards → `summary.pendingLeaveRequests`; Today's shifts → `todayShifts`. `summary.unreadNotifications` remains parsed but the header badge continues to use the canonical notifications endpoint. The API has no recent-activity feed, active/suspended split, percentages, comparisons, or trends, so the old mock activity and invented indicators are not shown.

Employee Overview maps `employee`, `todayShift`, `attendance`, `nextShift`, `summary.pendingLeaveRequests`, `summary.approvedLeaveRequests`, and `recentLeaveRequests`. Manager totals are never rendered in the employee shell.

Confirmed employee-status, shift, Clock-in/out, attendance-review, and leave mutations invoke a typed dashboard invalidation callback only after their canonical success response. Workspace/session changes reload through scope binding, and app resume triggers a background refresh. Equivalent in-flight triggers are coalesced into at most one follow-up request. Background failures retain the last dashboard and do not change the successful feature mutation.

## Manual dashboard regression

Use non-production manager and employee accounts in the same test workspace. In ApiDog, authenticate as the role named in each row. A “background” refresh is automatic; “manual” means pull-to-refresh is the expected fallback.

| # | Action | Expected API request and response | Expected Flutter dashboard change | Manual refresh |
| --- | --- | --- | --- | --- |
| 1 | Log in as manager | `GET /api/v1/auth/me`, then manager dashboard `200` | Manager dashboard opens with no previous-user data | No |
| 2 | Select a workspace | `GET /api/v1/workspaces/{id}/dashboard` | Old cards clear; selected name/timezone and new snapshot appear | No |
| 3 | Inspect initial dashboard | Manager dashboard `200` with `date`, `timezone`, `generatedAt`, `summary`, `todayShifts`, `pendingLeaveRequests` | Loading becomes canonical cards/previews | No |
| 4 | Compare every visible value | Repeat manager GET in ApiDog | Every card equals its documented response field; no trends | No |
| 5 | Pull to refresh | One manager dashboard GET | Cards update; failed refresh retains prior cards | Yes, this is the action |
| 6 | Add/activate employee | `POST /api/v1/invitations/accept` or `PATCH /api/v1/workspaces/{id}/employees/{membershipId}` returns canonical active membership, then dashboard GET | `totalEmployees` changes only when membership becomes active | No after in-app activation; otherwise manual |
| 7 | Suspend employee | `PATCH /api/v1/workspaces/{id}/employees/{membershipId}` returns suspended membership, then dashboard GET | Active `totalEmployees` decreases | No |
| 8 | Create today-overlapping shift | `POST /api/v1/workspaces/{id}/shifts` returns canonical shift, then dashboard GET | `scheduledToday` and `todayShifts` update | No |
| 9 | Update shift | `PATCH /api/v1/workspaces/{id}/shifts/{shiftId}` returns canonical shift, then dashboard GET | Affected day/time preview updates | No |
| 10 | Cancel shift | `PATCH /api/v1/workspaces/{id}/shifts/{shiftId}/cancel` returns cancelled shift, then dashboard GET | Cancelled shift is excluded from today totals/preview | No |
| 11 | Employee Clock-in | `POST /api/v1/shifts/{shiftId}/clock-in` returns attendance, then employee dashboard GET | Employee attendance appears; manager sees new value after its next refresh | No for employee; manager session manual |
| 12 | Employee Clock-out | `POST /api/v1/shifts/{shiftId}/clock-out` returns completed attendance, then employee dashboard GET | Attendance becomes completed with canonical minutes | No for employee; manager session manual |
| 13 | Approve/reject attendance | `PATCH /api/v1/workspaces/{id}/attendance/{attendanceId}/review` returns reviewed attendance, then manager dashboard GET | Approved metrics remain canonical; rejected attendance is excluded | No |
| 14 | Employee creates leave | `POST /api/v1/leave-requests` returns canonical pending leave, then employee dashboard GET | Pending count/recent leave update | No |
| 15 | Manager approves/rejects leave | `PATCH /api/v1/workspaces/{id}/leave-requests/{requestId}/review` returns reviewed leave, then manager dashboard GET | Pending leave count/preview update | No |
| 16 | Employee cancels leave | `PATCH /api/v1/leave-requests/me/{requestId}/cancel` returns cancelled leave, then employee dashboard GET | Pending count and recent status update | No |
| 17 | Open notifications | Notification unread/list GETs | Bell remains functional; dashboard layout is unchanged | No |
| 18 | Use each Quick Action | No dashboard request until a successful mutation | Employees, Shifts, and Requests destinations still open | No |
| 19 | Open profile/avatar | Existing profile/avatar GET | Header avatar remains canonical | No |
| 20 | Switch workspace | Manager path or employee query uses only new workspace UUID | Old data clears immediately; new timezone/data load | No |
| 21 | Logout A, login B without restart | Auth/me plus B dashboard GET | No A workspace, name, counts, shifts, or leave records appear | No |
| 22 | Disable network and refresh | Dashboard GET fails with network error | First load shows retry; refresh retains prior cards | Yes to retry |
| 23 | Simulate timeout | Dashboard GET times out | Safe timeout message; prior dashboard retained | Yes to retry |
| 24 | Exercise `401`, `403`, `404`, `429`, `502` | Dashboard GET returns each envelope with `requestId` | Safe message; sign-out only after final auth refresh failure | Yes after recoverable errors |
| 25 | Background and resume app | One coalesced dashboard GET on resume | Snapshot refreshes without disruptive toast | No |
| 26 | Test 320px-wide device and long workspace name | Normal dashboard `200` | No overflow; large counts scale down | No |
| 27 | Cross-check manager vs employee | Manager endpoint rejects employee `403`; employee endpoint rejects manager/inactive membership `403` | Employee sees Overview only; manager totals remain inaccessible | No |

Dashboard creation is not a mutation. All test data changes use the existing employee, shift, attendance, and leave business endpoints; no SQL or direct production data setup is required.

## Attendance calendar and workspace switching

The manager Calendar tab lazily loads the visible workspace-local month through the existing authenticated repositories. It exhausts all pages with the API maximum `limit=100` from:

- `GET /api/v1/workspaces/{workspaceId}/shifts`
- `GET /api/v1/workspaces/{workspaceId}/attendance`
- `GET /api/v1/workspaces/{workspaceId}/leave-requests?status=APPROVED`

Local month start and exclusive next-month start are constructed in the active workspace IANA timezone and converted to UTC for `from` and `to`. Client derivation then excludes boundary-only records and deduplicates canonical IDs. A valid non-rejected attendance is Present, or Late when `minutesLate > 0`; an ended non-cancelled shift without valid attendance is Absent unless approved leave overlaps that local day; approved overlapping leave is Leave. Future shifts are not absent, cancelled shifts are ignored, and rejected or unknown attendance cannot produce a known attendance state. A day can show several status dots because its selected-day list retains one derived outcome per employee.

Profile reuses the same active-membership chooser as initial workspace selection. Only active Manager and Employee memberships are selectable, the current workspace is identified, switching persists the workspace ID without signing out, and the session status routes to the correct role shell. Emitting the intermediate session-loading state clears all workspace feature scopes before activation, while each Cubit's generation guard rejects old responses.

Calendar refresh is routed by the selected Attendance tab and is triggered after successful shift, attendance-review, clock, and leave mutations. First-load failures support retry; background failures retain the last valid month. Holiday data is deliberately absent: the backend has no confirmed holiday model or endpoint, and weekends are not treated as holidays. Holiday support remains a future backend capability.

### Manual attendance-calendar regression

1. Sign in as a Manager with two active workspaces and open Profile.
2. Confirm Switch workspace is full width, immediately above the distinct Sign out action.
3. Open the chooser and confirm the active workspace is marked Current.
4. Confirm suspended, inactive, and unknown-role memberships are absent.
5. Switch Manager-to-Manager and verify the workspace ID persists after an app restart.
6. Switch Manager-to-Employee and back Employee-to-Manager; verify the correct shell and no prior-workspace data.
7. With one eligible workspace, tap Switch workspace and verify the safe informational toast without logout.
8. Open Attendance > Calendar and compare all three paginated API queries in ApiDog for the visible UTC range.
9. Navigate across a DST-changing month and verify its UTC offsets while local dates remain correct.
10. Verify Present, Late, Absent, and Leave dots against canonical records; confirm no Holiday legend.
11. Select mixed-status days and verify employee identity, shift times, clocks, lateness, and leave type.
12. Confirm future shifts are not absent and cancelled/rejected/unknown records do not grant misleading states.
13. Pull to refresh each Attendance tab and verify only its corresponding Cubit/API reloads.
14. Mutate shifts, attendance review, clocks, and leave; verify refresh occurs only after success and failed refresh retains the month.
15. Verify 320px, 360px, 390px, larger phones, large text, long names, large dashboard counts, and the full-width Today at a glance card without overflow.

## Verification

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

Automated tests use fakes and an in-memory Dio adapter; they never call production Supabase or Vercel.

## Still mocked

Dashboard summary cards and other features outside these integration sprints still use presentation mocks. Shift management, employee shifts, Clock-in/out, manager attendance review, employee attendance history, employee/manager leave requests, and notifications use API repositories in production. Employee and workspace management remain API-backed from the prior integration sprint. Mock repositories remain available only for isolated tests and no-session previews.
## Chat Sprint 1 manual regression

Use authorized non-production manager and employee accounts. Do not use production data.

1. Log in as a manager.
2. Select the intended workspace.
3. Create a manager-only group and confirm an empty employee selection is accepted.
4. Create a group with one or more active employees.
5. Verify the manager appears exactly once.
6. Verify the canonical member count in the group list and details.
7. Log in as an included employee in another session.
8. Confirm the included employee sees the group.
9. Confirm an excluded employee cannot see the group.
10. Send a text message from the manager.
11. Verify the employee receives the canonical REST-backed message after the Realtime event.
12. Send a text message from the employee.
13. Verify the manager unread badge updates.
14. Open the conversation and verify the unread count clears.
15. Simulate a failed send, retry it, and confirm only one message exists for the reused client message ID.
16. Load older messages and confirm chronology, deduplication, and scroll position remain stable.
17. Edit the group and verify list metadata is retained after canonical refresh.
18. Add an employee and verify canonical details and member count.
19. Remove an employee after confirmation and verify immediate access denial and removal from canonical details.
20. Archive the group after confirmation.
21. Confirm its history remains readable.
22. Confirm sending, editing, archiving, and member operations are disabled.
23. Switch workspace and verify old groups, messages, and unread state clear immediately.
24. Log out User A and log in as User B without restarting; verify no User A chat state returns.
25. Exercise offline, timeout, `401`, `403`, `404`, `409`, `429`, `500`, and `502` responses and verify safe errors, retry behavior, request IDs in diagnostics, and retained canonical data where applicable.
# Chat media integration

Shiftly chat supports canonical `TEXT`, `IMAGE`, `VOICE`, and `LOCATION`
messages. Unknown future message types are retained and rendered as an inert
fallback. The feature extends the existing authenticated Dio repository,
session-scoped Cubits, GoRouter routes, Supabase session, Realtime subscription,
toast/error pipeline, and shared chat screen; there is no second authentication,
routing, state-management, or backend mutation path.

## Media architecture and packages

- `image_picker` (existing) selects images. Bytes are bounded and checked for
  JPEG, PNG, or WebP magic bytes rather than trusting the extension.
- `record` records AAC-LC in an M4A container and requests microphone access only
  when recording starts. `path_provider` provides the temporary recording folder.
- `just_audio` provides play/pause/resume/replay. A single player belongs to the
  active conversation, so starting another item replaces the previous source and
  leaving the screen disposes playback.
- `geolocator` performs one bounded, foreground location request after the user
  selects Share location. No continuous tracking or location history is used.
- `url_launcher` opens a generated HTTPS Google Maps query in an external app.
  Backend text is never interpreted as a URL.

For IMAGE and VOICE, the client validates locally, calls
`POST /workspaces/{workspaceId}/chat/groups/{groupId}/uploads`, uploads bytes with
the initialized `SupabaseClient` Storage API using the exact returned bucket,
path, and upload token, the validated content type, and `upsert: false`, then
finalizes through
`POST /workspaces/{workspaceId}/chat/groups/{groupId}/messages`. Finalization
uses the original upload ID and a stable UUID-v4 `clientMessageId`; only the
canonical returned message enters history. A pre-finalization failure or user
cancellation attempts `DELETE .../uploads/{uploadId}`. A finalization failure
retains the same upload/client IDs for a safe retry. Storage success alone is
never shown as a sent message, and the client never constructs a bucket path or
public URL.

Pending media explicitly progresses through preparing, uploading, finalizing,
sent, failed, or cancelled. Completion is surfaced after the Storage API returns.
Duplicate execution of the same pending job is suppressed. Image preview bytes
exist only for the pending UI and are dropped after canonical success. Voice files are created
only in the OS temporary directory and deleted after reading, cancellation, or
failure; in-memory retry data is cleared after upload/cancel/session change.

Backend limits mirrored for early feedback are: JPEG/PNG/WebP images up to 5 MiB;
MP4/AAC/MPEG/Ogg/WebM voice up to 10 MiB and 600,000 ms. The backend remains
authoritative and verifies stored MIME, size, and signature. Location coordinates
must be finite with latitude in `[-90, 90]`, longitude in `[-180, 180]`, and at
most six decimal places server-side. Users always confirm a retrieved location
before it is sent.

## Permissions

Android declares only `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, and the existing
`INTERNET` permission. iOS declares `NSMicrophoneUsageDescription`,
`NSLocationWhenInUseUsageDescription`, and the existing photo-library reason.
Microphone and location runtime prompts occur only after the corresponding chat
action. Denied, permanently denied, disabled-service, timeout, cancellation, and
unavailable-device cases produce safe user messages.

## Realtime, session isolation, and errors

Realtime subscribes only to inserts for the active `group_id` through the current
authenticated Supabase session. Events and connection failures are bounded,
debounced invalidation signals; presentation data is refetched from NestJS.
Subscription callbacks, HTTP responses, uploads, read positions, and refreshes
are guarded by user, workspace, membership, role, group, and local session
generation. Scope changes immediately clear messages, pending bytes, playback,
and the old subscription. Cursor pages are deduplicated by canonical message ID
and sorted by `(createdAt, id)`. Loading older pages preserves scroll position;
new messages only auto-scroll when the reader is already near the bottom.

Archived groups remain readable and disable every composer action. API failures
preserve canonical history and flow through the typed safe-message mapping for
400, 401, 403, 404, 409, 413, 415, 429, 500, 502, network, timeout, and
cancellation cases. `requestId` remains available internally. Signed URLs,
upload tokens, file paths, media bytes, coordinates, provider bodies, and access
tokens are never logged or placed in exception `toString()` output.

## Manual chat-media regression plan

The conversation surface uses focused custom presentation widgets and a normal
chronological `ListView`. Shiftly's existing Cubits remain authoritative for canonical messages,
pending uploads, pagination, retries, cancellation, read state, and Realtime
refreshes. The adapter preserves backend message and membership IDs; custom
renderers keep signed-media URL retrieval and the single shared audio player in
the existing application-owned lifecycle. Destructive confirmations and form
workflows use the shared `ShiftlyChatDialog` abstraction without changing
repository mutations.

1. Use separate manager and employee sessions in the same group; verify both
   render all four message types and only authorized groups are visible.
2. Send JPEG, PNG, and WebP images; verify preview/progress becomes exactly one
   canonical bubble. Retry a network failure, reject spoofed/GIF and >5 MiB
   files, and confirm removing a failed item cancels it.
3. Test microphone grant, denial, permanent denial, interruption, cancel, a
   zero-length recording, automatic 10-minute limit, upload, play/pause/resume,
   replay, switching between voice items, background/resume, and screen exit.
4. Test location service disabled, grant/deny/permanent deny, timeout, cancel the
   confirmation, confirm sending, rendering, and opening the external maps app.
5. Keep two simultaneous sessions open; send each type in both directions and
   verify one debounced canonical refresh without duplicates or forced scrolling.
6. Verify unread totals and read positions synchronize after foreground refresh
   and Realtime delivery.
7. Load several older cursor pages and verify ordering, deduplication, and stable
   scroll position.
8. Archive a group and verify history remains readable while text and all attach
   actions are disabled for manager and employee.
9. Remove the employee while chat is open and verify the next canonical 403/404
   removes access and no old event changes the screen.
10. Switch workspaces during refresh, upload, recording, playback, and location;
    verify old data and operations cannot enter the new scope.
11. Log out User A and sign in User B without restarting; verify no messages,
    media, pending bytes, player state, URLs, or subscriptions survive.
12. Exercise offline, timeout, 401, 403, 404, each upload 409 state, 413, 415,
    429, 500, and 502; verify safe text, preserved canonical history, stable-ID
    retry, and no fake canonical message.
13. Background/resume while recording, uploading, playing, and awaiting location;
    verify resources settle safely and no duplicate finalization occurs.
14. Repeat composer, long-name/text, image, voice, location, loading, empty,
    error, and offline states on a narrow Android device.
15. Inspect debug/release logs for credentials, bearer tokens, signed URLs,
    upload tokens, provider responses, local paths, coordinates, and personal
    data; none should appear.

Remaining device-level risk is codec/provider behavior across OEM Android and iOS
versions, which must be covered by the manual matrix above. Signed media URLs are
short-lived (10 minutes), so an already-rendered image or active player may need a
fresh user action after expiry. Upload authorizations expire after two hours; the
UI retries expired pre-finalization work with a new authorization while preserving
the logical client message ID.

### Real-device IMAGE and VOICE upload retest

The signed uploader uses `uploadBinaryToSignedUrl` on the already initialized
Supabase client. It accepts only the `chat-media` bucket, rejects empty or
traversing paths, invalid or expired authorization records, and changed MIME/size
metadata, and passes the backend path and token without reconstructing either.
The exact validated `Uint8List` and content type are sent with `upsert: false`.

1. Cleanly uninstall and reinstall the debug application.
2. Sign in with a non-production account.
3. Enter an authorized, non-archived chat group.
4. Send a small JPEG.
5. Confirm upload initiation returns 201, Storage PUT succeeds, finalization
   succeeds, and exactly one canonical image bubble replaces the pending item.
6. Repeat with a valid PNG and WebP.
7. Record and send a short voice message.
8. Confirm `durationMs` is a positive integer, Storage succeeds, finalization
   succeeds, and playback works.
9. Interrupt the Storage PUT, then retry and confirm no finalization occurred for
   the failed PUT.
10. Send voice and immediately send image, then reverse the order; confirm each
    pending card keeps its own type, preview/duration, bytes, MIME, and ID.
11. Fail and retry one image and one voice upload; confirm each keeps its stable
    logical client message ID and correct pending presentation.
12. Disable connectivity during Storage upload; confirm finalization is not called
    and the safe Storage failure remains retryable.
13. Interrupt finalization after Storage success, retry the same pending item, and
    confirm the stable client message ID prevents duplication.
14. Verify unsupported MIME, oversized content, and archived groups show safe
    failures.
15. Confirm another authorized session receives the canonical message through
    Realtime invalidation and REST refresh.
16. Confirm successful JPEG, PNG, WebP, and voice finalizations do not return
    `CHAT_MEDIA_OBJECT_INVALID`, and image pending cards never say “Voice message”.
17. Inspect logs for tokens, signed URLs, Storage paths, bytes, filenames,
    authorization headers, coordinates, personal data, and provider bodies; none
    may appear.
18. If finalization still returns 400, record only the backend error `code` and
    `requestId`. `CHAT_MEDIA_OBJECT_MISSING` or `CHAT_MEDIA_OBJECT_INVALID` points
    to the uploaded object; `CHAT_MEDIA_VERIFICATION_FAILED` points to Storage
    access/provider configuration and requires checking deployed Storage policies
    without weakening backend verification.

### Modern chat UI checks

1. Verify the group list shows initials, name, last-message preview, member count,
   timestamp, unread badge, and archived state at narrow and wide widths.
2. Verify the chat header shows identity, member count, read-only state, and only
   actions allowed by the current role.
3. Send and receive text, image, voice, and location messages; verify sender-side
   alignment, grouping order, day separators, safe unknown-type fallback, and no
   duplicate canonical IDs.
4. Load older pages repeatedly and verify stable ordering and scroll position;
   then receive a Realtime refresh and verify the visible state remains coherent.
5. Verify private images show loading and recoverable error states, open a zoomable
   full-screen preview, and never write signed URLs to logs or persistent state.
6. Play, pause, resume, replay, and switch between voice messages; verify only one
   source plays, progress follows the active source, and backgrounding stops media.
7. Exercise create, edit, archive, add-member, remove-member, cancel-upload,
   discard-recording, and location-confirm dialogs, including failure and retry.
# Fixed shifts and flexible attendance

The fixed-shift feature is additive to the legacy scheduled-shift flow. Production wiring creates one `ApiFixedShiftRepository` from the existing authenticated Dio client and the existing `SharedPreferences` instance. `ManagerTemplatesCubit` and `FlexibleAttendanceCubit` are application-scoped, role-gated, and rebound whenever the authenticated feature scope changes. Employee work-pattern state is local to Employee Details. Legacy `ShiftRepository`, `AttendanceRepository`, screens, Cubits, and routes remain available.

## Endpoint mapping

| Flutter operation | API operation |
| --- | --- |
| List/create templates | `GET/POST /api/v1/workspaces/{workspaceId}/shift-templates` |
| Template detail/edit/archive | `GET/PATCH/DELETE /api/v1/workspaces/{workspaceId}/shift-templates/{templateId}` |
| Work-pattern history/replacement | `GET/POST /api/v1/workspaces/{workspaceId}/employees/{membershipId}/work-patterns` |
| Employee template catalog | `GET /api/v1/shift-templates/me?workspaceId=...` |
| Eligibility | `GET /api/v1/shift-templates/eligibility?workspaceId=...` |
| Flexible clock-in | `POST /api/v1/attendance/flexible/clock-in` |
| Restore active attendance | `GET /api/v1/attendance/me/current?workspaceId=...` |
| Flexible clock-out | `POST /api/v1/attendance/{attendanceId}/clock-out` |

Managers open Fixed Shift Templates from the existing Shifts header. Creating and editing uses time pickers, accessible color choices, policy controls, and a live same-day/overnight/24-hour summary. Archive is explicitly presented as a reversible-history concept rather than permanent deletion. Work patterns appear in Employee Details, show the canonical current and historical versions, accept unique weekday chips, and restrict the effective date to workspace-local today or later.

Employees use the existing Attendance destination. It restores open attendance first, displays backend-calculated eligibility and recommendation, and confirms the operational date and classification before clock-in. The client sends only `workspaceId`, `shiftTemplateId`, and a UUID-v4 `clientAttendanceId`; no device timestamp is sent. The UUID and its user/workspace/membership/template scope are persisted before submission and reused after timeout, offline, cancellation, or server ambiguity. It is cleared only after canonical success or a confirmed terminal rejection. Clock-out renders the canonical response and never calculates stored worked minutes locally.

All server timestamps are parsed as UTC instants and displayed with the workspace IANA timezone. Operational dates and eligibility are never recalculated on-device. Invalid IANA zones disable local calendar mutation and surface the stable backend error. Attendance decoding branches on `source`; legacy `shiftId/shift` and template snapshot fields are nullable so both record types continue to render during migration. Unknown source/classification values remain unknown and do not enable attendance actions.

The only remaining fixed-shift mock is `PreviewFixedShiftRepository`, an empty adapter used when `ShiftlyApp` is launched without an authenticated session by widget previews/tests. Authenticated production startup requires explicit `FixedShiftRepository` injection and never falls back to it. The points system is intentionally deferred.

## Manual ApiDog and Flutter regression plan

1. Authenticate as a manager, select an active workspace, and smoke-test all legacy shift create/edit/cancel, attendance review, leave, dashboard, notification, and chat paths.
2. In ApiDog create same-day, overnight, and equal-boundary 24-hour templates. Verify `minimumWorkMinutes` boundaries, duplicate active names, partial PATCH merged validation, archived read-only behavior, pagination, wrong-workspace IDs, and manager/employee authorization.
3. In Flutter open Shifts > Fixed Shift Templates on a narrow Android device and a tablet. Verify loading skeleton/progress, empty, retry, pull-to-refresh, retained-data warning, long names, both themes where enabled, time pickers, color contrast, policy validation, duplicate-submit prevention, edit, and archive confirmation.
4. Open an active employee. Create patterns effective workspace-local today and in the future, verify unique weekdays and version history/end dates, then attempt a backdate, duplicate date, concurrent replacement, suspended employee, wrong workspace, and invalid timezone. Confirm Flutter refreshes canonical history rather than editing it optimistically.
5. As that employee, inspect Attendance before, at, and after early/grace/late window boundaries for same-day and overnight templates. Verify the recommended occurrence, other eligible occurrences, classification, late minutes, operational date, no-pattern state, no-eligible state, archived templates, and timezone/DST display against ApiDog responses.
6. Confirm clock-in sends exactly the three documented fields and no timestamp. Simulate offline, timeout, and 502 after send; retry and verify the identical UUID returns the same attendance. Reuse that UUID with another template/workspace and confirm safe idempotency-conflict guidance.
7. Race taps and concurrent requests. Verify one open attendance, disabled duplicate actions, canonical current restoration after force-stop/relaunch, and immediate clearing of old data on workspace switch, logout/login, suspension, role change, and session-generation change.
8. Clock out, repeat clock-out, and verify both return the same completed attendance. Confirm server worked minutes, history, dashboard, eligibility, and notification counts refresh; then force one secondary refresh to fail and verify the successful mutation remains visible.
9. Re-run legacy employee shift clock-in/out and mixed legacy/template attendance history. Verify template records never require `shiftId`, legacy records never fabricate a template, manager review remains functional, and calendar aggregation remains based on legacy scheduled shifts until its template-specific design is introduced.
10. Exercise HTTP 400, 401, 403, 404, 409, 429, 500, 502, malformed 2xx, timeout, cancellation, and offline responses. Verify friendly messages and support `requestId`, with no provider detail, token, personal data, request body, or idempotency UUID in logs.
