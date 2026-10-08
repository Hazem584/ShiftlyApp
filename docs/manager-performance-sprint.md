# Manager Performance & Points sprint

Reviewed on 2026-10-08. Flutter HEAD: `1572ab8895a88fa03a91e6d5c6411a7731d9bf27` (Master). Backend HEAD: `74768e3d2af26264bc5435da2e15e77964a9b04d` (main). Each repository had one worktree and a clean working tree before edits. No applicable AGENTS.md was found in either repository or their ancestors. Backend files are read-only for this implementation.

Contract authorities: backend `src/modules/points/points.controller.ts`, `dto/points.dto.ts`, `points.service.ts`, `points.service.spec.ts`, related lifecycle tests, `prisma/schema.prisma`, workspace access guard/membership service, and the existing `.artifacts/openapi.json`. Exported Swagger has placeholder response schemas; source determines real fields. No live API calls were made.

## Confirmed endpoint/action map

Paths below are relative to the configured authenticated API base. `W` = `/workspaces/{workspaceId}/points`; `E` = `/workspaces/{workspaceId}/employees/{membershipId}/points`. The target is a workspace membership ID, never an authentication/profile ID. Every manager controller requires an authenticated active MANAGER membership in that workspace. Reads allow historical suspended employee records where the service permits; new employee mutations require an active target employee. Backend actor identity comes from the authorized request membership.

| Method/path | Fields, query and envelope | Flutter action |
| --- | --- | --- |
| GET W/policies | Direct array; versions with id, effectiveFrom/effectiveTo as local date strings, creator and settings | Version history, expandable settings |
| GET W/policies/current | Direct policy object | Current effective policy |
| POST W/policies | effectiveFrom plus only supported policy settings; no UUID | Confirm a new future version |
| GET W/summary | page/limit/search (search 1–100); `{data,pagination}` | Search and paginate active employees; row id is membership ID |
| GET W/disputes | page/limit/status PENDING/APPROVED/REJECTED/CANCELLED; `{data,pagination}` | Filtered paginated disputes |
| GET W/disputes/{id} | Direct record, related targetLedgerEntry where included | Private detail and event evidence |
| PATCH W/disputes/{id}/review | decision APPROVED/REJECTED, trimmed response 5–1000; no UUID | Confirm review; canonical detail refresh |
| GET W/warnings | Direct array, newest 100; cycle, threshold, createdAt, employeeMembershipId | Workspace warnings and employee links |
| GET E | Canonical wallet: workspace/timezone, green, black, red, orange, blue, streak, policy | Manager wallet, compensation totals; no redemption action |
| GET E/history | page/limit/pointType/reason/from/to; `{data,pagination}` | Immutable history with point-type filter and pagination |
| GET E/calendar | year 2000–2100, month 1–12; direct array | Monthly calendar and authoritative day details |
| GET E/achievements | Direct array; active badgeType, earnedAt, period | Non-spendable badges and award dates |
| GET E/warnings | Direct newest-100 array | Employee warnings |
| POST E/extra-effort | reason enum, trimmed explanation 5–1000, optional attendanceId UUID-v4, optional bluePoints 1–100, required clientAwardId UUID-v4 | Structured BLUE award; explicit quantity; server computes GREEN |
| GET E/extra-effort | Direct newest-100 array; ledgerEntries, policy/creator, bluePoints, greenBonus, reversal audit fields | Awards and immutable reversal status |
| POST E/extra-effort/{id}/reverse | trimmed reason 3–100, explanation 5–1000, clientReversalId UUID-v4 | Confirm reversal of linked BLUE/GREEN entries |
| POST E/adjustments | pointType GREEN/BLACK/RED/ORANGE/BLUE, amount integer -100…100 excluding zero, reason enum, explanation 5–1000, clientAdjustmentId UUID-v4 | Confirm add/subtract; server balance validation |
| GET E/adjustments | Direct newest-100 array with ledgerEntries and reversal audit fields | Adjustment records |
| GET E/adjustments/{id} | Direct scoped object | Canonical detail before reversal |
| POST E/adjustments/{id}/reverse | adjustment reason enum, explanation 5–1000, clientReversalId UUID-v4 | Confirm immutable adjustment reversal |

Paginated routes use page >=1, limit 1–100 (UI requests 20), pagination `{page,limit,total,totalPages}`. History dates are real YYYY-MM-DD dates. List endpoints without pagination do not accept invented cursors or filters. Errors use the shared ApiErrorParser and backend status/code contracts.

Extra-effort reasons: COVERED_EMPLOYEE, ADDITIONAL_SHIFT, APPROVED_OVERTIME, EMERGENCY_SUPPORT, HIGH_WORKLOAD_SUPPORT, OTHER. Adjustment/reversal reasons: TECHNICAL_CORRECTION, ATTENDANCE_CORRECTION, POLICY_EXCEPTION, DISPUTE_RESOLUTION, OTHER.

Policy fields and bounds: greenPointsForCompletedAttendance, blackPointsForLateAttendance, redPointsForAbsence, orangePointsForIncompleteAttendance, bluePointsForExtraEffort, blueGreenEquivalent, monthlyRedCompensationLimit, streakGreenReward: integers 0–100. greenCostPerRedCompensation and blackPointsWarningThreshold: 1–1000. disputeWindowHours: 1–2160. earlyDepartureToleranceMinutes: 0–1440. incompleteAttendanceResolutionMinutes: 1–10080. streakRequiredDays: 1–365. streakRewardEnabled and isEnabled: booleans. effectiveFrom: real workspace-local date. The backend permits today/future, rejects backdating and dates at/before a later version; the UI deliberately requires a future date later than all existing versions. Each version is created independently; omitted fields would use backend defaults, so the form sends every supported setting explicitly.

## Navigation, state and audit behavior

Dashboard → Performance → Overview / employees, Points Policies, Disputes, Warnings. Overview and Employee Details open `/dashboard/performance/employees/{membershipId}`. Employee Performance has Calendar, Ledger history, Achievements, Warnings, Extra effort, Adjustments and focused confirmation dialogs. Existing bottom navigation is preserved.

ManagerPerformanceCubit is separate from the employee PointsCubit. GetIt registers the manager repository and intent storage; requests use the shared authenticated Dio. App session coordination binds user/workspace/actor/role/status/timezone/generation. Scope changes immediately clear visible resources and reject stale results; server-confirmed workspace access/role loss also disables the old scope. Modal private details and confirmations hide their contents when scope changes. Resources have independent request identities, employee keys, filter isolation, page deduplication, duplicate-load suppression and one queued refresh per resource. Ordinary refresh errors retain canonical records.

UUID operations normalize once, persist before any submission, and preserve their exact payload/UUID across retries and restart. One unresolved operation blocks new mutations across employees; the storage key contains user/workspace/actor and the stored intent contains target/action. Recovery never submits automatically. Transport errors, unknown rejection codes, authentication failures and UUID conflicts retain saved requests. Confirmed success or verified terminal rejection clears them; failed storage cleanup keeps recovery blocked. Canonical success is not downgraded by refresh failure. Policies and dispute reviews without UUIDs recover through reads, comparing fields and actor; a pending dispute or absent policy version remains unresolved because a read cannot prove an in-flight request will not commit later.

Backend ledger/audit behavior is retained: no ledger editing or deletion, no client final-balance calculation, no manual GOLD, no manager redemption, no warning-triggered suspension, no public ranking. BLUE awards and reversals include linked server-created GREEN changes. Adjustment creation/reversal returns canonical ledger-linked audit records. UI confirms identity, submitted fields, reversal state and known success status before treating API writes as confirmed. Unknown point/status enums use neutral labels; malformed wallet/calendar/achievement/history successes become parsed failures.

## Fixed shifts and preserved legacy attendance

`/dashboard/shifts` opens ShiftTemplatesScreen directly. The former ManagerShiftsScreen is a compatibility wrapper for the same screen and contains no legacy create/edit/cancel controls. Dashboard quick actions use this route; repository search found no other active assignment editor callers. Work Pattern management, template create/edit/archive, archived filtering, overnight/24-hour durations, check-in settings and timezone remain unchanged.

Employee My Shifts opens EmployeeFixedShiftsScreen with available templates and FlexibleAttendancePanel. Employee overview links there and labels any backend legacy schedule explicitly. A separate Legacy shift history / active clock-out entry keeps old records readable and existing open legacy attendance finishable. New legacy clock-in is no longer exposed by the history view. Existing flexible attendance logic, legacy restoration and backend endpoints/database records remain intact. Old employee shift notifications are validated before opening the fixed-shift destination; the history entry is available there. Unavailable/retired destinations give safe feedback.

## Supported-scope limits

All requested manager mutation endpoints exist. The backend caps warnings, awards and adjustments at 100 records and provides no pagination for them; the UI states this. No unsupported analytics, rankings, GOLD manipulation, manager redemption or disciplinary automation were added. The optional award attendance reference is supported by the repository contract but the initial award form uses reason, explanation and explicit BLUE quantity. History repository supports reason/from/to filters; this UI exposes the point-type filter. Ambiguous non-UUID operations may require support investigation when canonical reads remain pending/absent; no unsafe resend control is shown.

No new package dependencies, backend changes, deployments, configuration changes, SQL or migrations are required by these Flutter changes. Deploy the Flutter client against the reviewed existing backend contract. Preview without that backend explicitly reports Manager Performance unavailable.

Changed files: the new feature is under `lib/features/manager_performance/{data,presentation}`; template employee view is `lib/features/fixed_shifts/presentation/widgets/employee_fixed_shifts_screen.dart`. Integration edits are in app providers, dependency registration, routing, dashboard quick actions/employee overview, Employee Details, employee shell, retired manager shifts wrapper, legacy employee shifts labels/clock-out controls, flexible attendance guidance and notification navigation. Tests: manager_performance_contract_test.dart, manager_performance_reliability_test.dart, manager_performance_widget_test.dart and test/support manager fixtures; existing dashboard and shift-navigation expectations were updated. Attendance rejection dialog/controller code is untouched.

## ApiDog + Flutter regression plan

Use an isolated staging workspace with two managers, two employees, a separate workspace and separate user. Never use production data.

1. In ApiDog, call every mapped manager endpoint with MANAGER, EMPLOYEE, suspended membership and another workspace's token/target. Verify authorization errors and no cross-workspace data. In Flutter, switch user/workspace/role during delayed reads and open dialogs; private data disappears and old controls cannot submit.
2. Open Dashboard Performance and Employee Details → Performance. Confirm row targets are membership IDs. Search/filter/page independently; switch employees while requests are pending. Verify retained data plus error on refresh failure and no duplicate pages.
3. Compare wallet, compensation totals, all five point types, calendar statuses/day details, ledger and badge dates with canonical ApiDog reads in the workspace timezone. Check pending/unknown statuses, empty results and malformed test responses. Verify no manager redeem/GOLD/ledger-edit controls.
4. Add and subtract each supported point type using adjustments; check exact enum/reason/explanation and quantities. Attempt zero/out-of-range values and insufficient balances. Confirm server totals and immutable ledger/audit records across manager and employee views.
5. Award structured BLUE using each reason. Compare server-derived linked GREEN with the effective policy; never infer final balances in Flutter. Reverse an award and an adjustment; inspect immutable reversal entries, reason/explanation, canonical reversedAt and repeat/already-reversed conflicts.
6. Drop responses after a committed adjustment/award/reversal. Double tap, restart and switch scopes; verify exactly one UUID/payload is persisted and no automatic submission. Retry the exact saved request and compare canonical results. Simulate 408/429/5xx, 401/403, UUID conflicts, failed storage writes and cleanup failures; uncertain operations remain blocked, confirmed success survives refresh failure.
7. Create a future policy after existing versions. Verify every numeric/boolean bound, invalid dates, timezone day boundaries, backdated/same-date conflicts and history. Lose the response; recovery reads versions and compares actor/settings without sending invented UUIDs or another POST. Check historical attendance retains its version.
8. As employee, dispute an eligible ledger event using ApiDog/existing supported client flow. Manager filters and opens evidence, confirms APPROVED/REJECTED plus response; employee sees canonical resolution. Review concurrently from the second manager; handle already-reviewed conflict. Lose a review response; read status/response/actor before another action.
9. Compare workspace and employee BLACK warnings with ApiDog cycle/threshold/date fields. Confirm capped-list guidance and no automatic suspension or public negative-point leaderboard.
10. Open manager Shifts from all active routes/quick actions: templates appear directly, with no legacy assignment choice/FAB/create/edit/cancel action. Create/edit/archive/filter templates, including overnight and 24-hour schedules; update employee Work Pattern. Employee My Shifts shows templates, eligibility and flexible clock-in/out.
11. Restore existing open legacy attendance and finish clock-out through the labelled history entry. Inspect historical attendance without fabricated template snapshots. Open valid and inaccessible old shift notifications; use history or receive safe feedback, never reopen manager assignment UI.
12. Exercise 320px layouts, increased text scale, light/dark Material themes, keyboard/scrolling, confirmations, dismissal and scope loss. Repeat attendance rejection dialog cancel/submit flows to guard its controller lifecycle. Check loading/empty/error/retained refresh states for each resource.

## Exact verification results

The normal `dart format .` launcher could not acquire the Flutter SDK cache lock under the restricted filesystem and never spawned the formatter. The stuck bootstrap wrapper was identified and stopped after confirming it had no child process. The installed SDK executable then performed the one actual `format .` pass: 606 files scanned, 27 changed, formatting completed in 3.55 seconds. The process exited 1 afterward because Dart telemetry could not update its session file outside the writable workspace. Formatting was not repeated.

`flutter analyze` ran once with SDK cache access: exit 1, three informational style diagnostics (two use_null_aware_elements, one prefer_interpolation_to_compose_strings), no reported compile errors. Those three locations were corrected afterward. Analysis was not repeated.

`flutter test` ran once with SDK cache access: exit 1, 375 passed, four failed. Failures: dashboard employee overview and unknown-attendance widget tests (the new ListTile had no Material ancestor in isolated rendering); manager employee-selection and compact scaled-control widget tests. The selection test's tap was off-screen. The dashboard link was wrapped in a Card; the new test harness now inherits the actual viewport, pumps after ensureVisible and explicitly scrolls to compact controls. Post-test review also added notification scope checks around asynchronous navigation, manager-specific achievement empty text and repository cancellation on manager scope changes/disposal so an authenticated retry cannot outlive its manager scope. These post-test edits were not reverified. The post-fix tree has no demonstrated clean formatter, analyzer or full-test result; do not treat this handoff as an all-checks-passed release.

The run passed the manager API contract/reliability tests, the new controller ownership/scope-loss and policy date dialog tests, direct template navigation, and the existing attendance rejection lifecycle tests. Tests used injected local adapters/repositories; no production request was made. No APK/app-bundle build, git diff --check, commit, push, deployment, history change, backend write or SQL/migration execution occurred.

## Changed file inventory

- docs/manager-performance-sprint.md
- lib/app/app_providers.dart
- lib/app/parts/app_providers/private_app_providers_state.dart
- lib/core/di/dependency_registration.dart
- lib/core/error/api_error_parser.dart
- lib/core/routing/app_router.dart
- lib/core/routing/app_routes.dart
- lib/features/dashboard/presentation/screens/employee_dashboard_screen.dart
- lib/features/dashboard/presentation/screens/parts/employee_dashboard_screen/private_employee_dashboard.dart
- lib/features/dashboard/presentation/widgets/dashboard_quick_actions.dart
- lib/features/employees/presentation/screens/employee_details_screen.dart
- lib/features/employees/presentation/screens/parts/employee_details_screen/private_employee_details_view.dart
- lib/features/fixed_shifts/presentation/widgets/employee_fixed_shifts_screen.dart
- lib/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart
- lib/features/manager_performance/data/api_manager_points_repository.dart
- lib/features/manager_performance/data/manager_intent_storage.dart
- lib/features/manager_performance/data/manager_mutation_intent.dart
- lib/features/manager_performance/data/manager_points_page.dart
- lib/features/manager_performance/data/manager_points_record.dart
- lib/features/manager_performance/data/manager_points_repository.dart
- lib/features/manager_performance/data/memory_manager_intent_storage.dart
- lib/features/manager_performance/data/preferences_manager_intent_storage.dart
- lib/features/manager_performance/data/unavailable_manager_points_repository.dart
- lib/features/manager_performance/presentation/cubit/manager_performance_cubit.dart
- lib/features/manager_performance/presentation/cubit/manager_performance_state.dart
- lib/features/manager_performance/presentation/cubit/manager_resource_state.dart
- lib/features/manager_performance/presentation/screens/employee_performance_screen.dart
- lib/features/manager_performance/presentation/screens/employee_performance_screen_state.dart
- lib/features/manager_performance/presentation/screens/manager_dispute_screen.dart
- lib/features/manager_performance/presentation/screens/manager_dispute_screen_state.dart
- lib/features/manager_performance/presentation/screens/manager_performance_screen.dart
- lib/features/manager_performance/presentation/screens/manager_performance_screen_state.dart
- lib/features/manager_performance/presentation/widgets/manager_action_dialog.dart
- lib/features/manager_performance/presentation/widgets/manager_action_dialog_state.dart
- lib/features/manager_performance/presentation/widgets/manager_audit_dialog.dart
- lib/features/manager_performance/presentation/widgets/manager_calendar.dart
- lib/features/manager_performance/presentation/widgets/manager_confirmation_dialog.dart
- lib/features/manager_performance/presentation/widgets/manager_form_field.dart
- lib/features/manager_performance/presentation/widgets/manager_forms.dart
- lib/features/manager_performance/presentation/widgets/manager_recovery_banner.dart
- lib/features/manager_performance/presentation/widgets/manager_resource_list.dart
- lib/features/manager_performance/presentation/widgets/manager_scoped_details.dart
- lib/features/notifications/presentation/screens/parts/notifications_screen/private_notification_navigator.dart
- lib/features/points/presentation/widgets/points_achievements.dart
- lib/features/shell/presentation/screens/employee_shell_screen.dart
- lib/features/shell/presentation/screens/parts/employee_shell_screen/private_employee_shell_screen_state.dart
- lib/features/shifts/presentation/screens/employee_shifts_screen.dart
- lib/features/shifts/presentation/screens/manager_shifts_screen.dart
- test/dashboard_test.dart
- test/manager_performance_contract_test.dart
- test/manager_performance_reliability_test.dart
- test/manager_performance_widget_test.dart
- test/shift_attendance_widget_test.dart
- test/support/delayed_manager_storage.dart
- test/support/manager_points_adapter.dart
- test/support/manager_points_fake.dart
