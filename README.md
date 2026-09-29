# Shiftly

Shiftly is a Flutter workforce app backed by Supabase Auth and the Shiftly NestJS API. Authentication, profile editing, avatar management, workspace membership, role-based routing, shifts, clock actions, and attendance use the production API while unrelated feature screens retain their mock repositories.

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

The app retains its feature-first structure, repository injection, Cubits, GoRouter, theme, and custom toast. Shared integration code lives under `lib/core/config`, `error`, `network`, `session`, `storage`, and `utils`. Authentication owns its service wrapper, API repository, models, screens, and focused widgets under `lib/features/auth`.

Production creates `ApiShiftRepository`, `ApiAttendanceRepository`, `ApiLeaveRequestRepository`, and `ApiNotificationRepository` with the existing authenticated Dio instance. Feature Cubits bind to the authenticated user, active workspace, active membership, and backend-confirmed role. A scope change clears data immediately and invalidates pending work. The mock repositories are limited to isolated tests and the no-session component preview entry point.

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
|---|---|---|---|---|
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
