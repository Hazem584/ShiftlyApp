# Assigned shifts and extra attendance integration

## Inspected baseline

- Flutter HEAD: `c979fe329486f8a4dfa0dd89c56a6f8ef31732d1`; initial tracked and untracked working tree clean.
- Read-only backend HEAD: `c5e89f5c527e1480dc98bfdadfd32a0ac63bea95`; initial working tree clean, matching the requested reviewed commit.
- No applicable `AGENTS.md` found in either repository or the workspace parents, including a hidden-file search excluding dependency/Git directories.
- Reviewed controllers, DTOs, attendance/extra/work-pattern/template services, assignment evidence, dashboard behavior, `.artifacts/openapi.json`, and `docs/assigned-shifts-handoff.md`. Source overrides incomplete generated OpenAPI examples.

## Confirmed contracts

All paths below use the existing authenticated Dio `/api/v1` prefix. Successes are plain objects; no additional envelope. Employee/audit IDs are workspace membership IDs, never profile or authentication IDs. Let `E=/workspaces/{workspaceId}/employees/{membershipId}`.

| Method and path | Request | Response |
| --- | --- | --- |
| GET `E/work-patterns` | `page`, `limit` (default 1/20, maximum 100) | `{current,history,pagination}`; current independent of requested history page |
| POST `E/work-patterns` | `shiftTemplateId`, unique `expectedWeekdays` (Sunday 0 through Saturday 6), `effectiveFrom` | Canonical version; nullable `shiftTemplateId`/`assignmentSnapshot` in historical versions, inclusive date bounds |
| GET `E/extra-shifts` | `page`, `limit` | `{data,pagination}` including AUTHORIZED, CONSUMED and REVOKED evidence |
| POST `E/extra-shifts` | `shiftTemplateId`, `operationalDate`, `reason`, normalized `explanation`, UUID-v4 `clientAuthorizationId` | Canonical authorization, immutable `occurrenceSnapshot`, creator/revocation/consumption audit and `attendance` array |
| DELETE `E/extra-shifts/{authorizationId}` | No body | Canonical revoked authorization; consumed authorizations cannot be revoked |
| POST `E/extra-shifts/attendance` | Authorization fields plus explicit-offset/Z `actualClockInAt`, `actualClockOutAt` | CONSUMED authorization and one linked closed APPROVED attendance with manager membership audit |
| GET `/shift-templates/me` | `workspaceId`, `page`, `limit` | Restricted assigned/authorized catalog with occurrence fields; no employee template selection authority |
| GET `/shift-templates/eligibility` | `workspaceId` | `status`, `evaluatedAt`, `timezone`, `recommended`, `eligibleTemplates`, `authorizedOccurrences`, nullable partial `openAttendance` |
| GET `/attendance/me/current` | `workspaceId` | Canonical open attendance or null |
| POST `/attendance/flexible/clock-in` | `workspaceId`, `shiftTemplateId`, UUID-v4 `clientAttendanceId`; baseline `assignmentId` OR extra `extraAuthorizationId` | Canonical attendance with occurrence linkage, operational date, immutable scheduled UTC instants and captured policy minutes |
| POST `/attendance/{attendanceId}/clock-out` | No body | Canonical closed attendance; idempotent repeat |
| GET `/attendance/me` | `workspaceId`, `page`, `limit` | Paginated history used to find committed saved UUIDs, including closed/rejected attendance |

Assignment dates are real `YYYY-MM-DD` values. Authorization/attendance operational dates can be UTC-midnight ISO strings; preserve their operational date rather than using the actual clock-in calendar date. Nullable evidence stays absent. Schedule snapshots contain saved template name/color, timezone, minutes and `conversionPolicy`. New policy is `POSTGRES_V1`; unversioned historical evidence is not relabeled. Unknown occurrence kinds, classification/policies, missing IDs, missing timezone or malformed eligibility do not grant clock-in.

Reasons exactly: `COVERED_EMPLOYEE`, `ADDITIONAL_SHIFT`, `APPROVED_OVERTIME`, `EMERGENCY_SUPPORT`, `HIGH_WORKLOAD_SUPPORT`, `OTHER`. Explanations trim and collapse whitespace and require 3–1000 characters. Actual attendance needs ordered nonfuture timestamps and a clock-in inside the occurrence window; backend validates overlap, membership evidence, expiry and reservations.

## Implementation and files

- `lib/features/fixed_shifts/data/`: shared-Dio exact endpoint implementations, standalone defensive models, immutable saved schedules, explicit canonical linkage and scoped durable employee/manager intents. Existing repository import remains a compatibility export surface.
- `lib/features/fixed_shifts/presentation/cubit/`: standalone Cubits/states, manager role and generation guards, retained data, paginated histories, canonical mutation success independent of refresh, startup and retry recovery, duplicate submission guards and consumed occurrence protection.
- `lib/features/fixed_shifts/presentation/widgets/`: manager assignment/extra forms with confirmation and retained input, saved schedule/audit cards, explicit manager attendance entry, optional extras clearly separated from baseline, compact wrapping layouts and state-owned controller disposal.
- Employee Details adds Extra Shifts alongside the versioned work-pattern section. Existing Employee Performance → Grant extra effort remains the explicit BLUE approval flow; entry does not create an award.
- `lib/core/utils/workspace_timestamp_input.dart`: explicit offset workspace-timezone input; validates calendar fields and round-trips each instant through existing timezone data. DST folds require the intended explicit offset; nonexistent wall times/wrong offsets are rejected. No device-local timestamps are submitted.
- Existing GetIt registration aliases the extra repository to the same fixed-shift API repository; no new client/router/service locator/state framework. Existing app resume hook refreshes flexible attendance. Canonical manager mutations use the established dashboard/calendar/Points/performance invalidation callbacks.
- Safe error mappings retain status, code and request ID in failures and never show provider messages.
- `test/fixed_shifts_sprint_test.dart`: fake-only endpoint/payload, defensive evidence, authorization, intent recovery/isolation, early/rejected consumption, stale/duplicate submissions, refresh failure, DST, narrow/scaled/dark form and controller lifecycle coverage. Full suite includes existing Points/attendance regressions.
- No dependencies added. No backend, SQL, migrations, production data, Firebase workflow, build or Git history changes.

## Recovery and deployment limits

Employee v3 storage holds one unresolved operation per user/workspace/membership, with template, kind, assignment/authorization, operational date, stable UUID and exact normalized supported HTTP payload. Manager storage similarly preserves the target membership, exact action and payload under the creating manager's authenticated scope. Intents are written before HTTP. Only canonical success or confirmed business/DTO rejection clears them; network/server/unknown errors, access changes and idempotency conflicts retain evidence. A remaining intent blocks new conflicting actions and assignment replacement. Canonical success is retained if storage cleanup or a secondary refresh fails.

Old v1/v2 clock-in intents lack trustworthy occurrence evidence. They remain stored and quarantined, never silently deleted or replayed against a new occurrence. The UI requires review; no destructive “discard” button is supplied. Open attendance and history remain available independently of this quarantine.

The flexible clock-in DTO cannot pin an operational date. Baseline recovery first searches canonical history for the saved UUID. If absent, replay is permitted only when fresh backend eligibility still exposes the exact original occurrence and its original window remains open. Expired or changed baseline recovery remains blocked for manager review. An in-flight request crossing a server occurrence boundary remains a backend contract limitation: the frontend validates canonical occurrence evidence and retains a mismatch for review. A fully date-pinned baseline retry would require a backend contract extension; no unsupported date field is sent. Extra retries remain pinned by the authorization ID. Authorization/role changes require restored valid access before recovery; no request is moved to another manager scope.

Backend migrations and deployment are prerequisites for live testing. Rehearse the full migration chain, including `20261009120000_assigned_shifts_and_extras`, `20261009130000_correct_occurrence_reservations`, and `20261009140000_version_occurrence_dst_policy`, and the backend handoff's read-only preflight/parity process in isolated staging. Coordinate DST-aware migration/backend cutover and timezone database versions. Nothing was deployed or applied by this Flutter task.

An unavailable/unupgraded backend produces safe retained-data errors or disabled/read-only attendance; no mock fallback. Dashboard services still count dated legacy shift obligations and query attendance through legacy shift relationships. Refresh their existing server data without manufacturing template/extra counters. EXTRA never substitutes for baseline GREEN/BLACK evaluation or automatically awards BLUE.

## Manual manager-to-employee sequence

1. In isolated staging with the complete migrations/backend deployed, sign in as an active manager. Create active daytime and nonoverlapping evening/overnight templates.
2. Open Employee Details for an active employee membership. Assign baseline weekdays effective workspace-local today. Confirm saved template, timezone, weekdays and dates; add a future version and paginate history. Edit the catalog template and verify old assignment schedules stay saved.
3. Attempt a backdate, captured-occurrence replacement and assignment/extra overlap. Confirm safe errors and preserved form selections. Retry after correcting the date/schedule.
4. Authorize a distinct extra with an exact reason/explanation. Verify canonical audit, paginate history, revoke an unused authorization and confirm read-only history. Attempt consumed revocation and overlapping/expired extra creation.
5. Sign in as that employee. Verify assigned baseline and distinct authorized extra cards, recommendation, operational start dates/timezone and outside-window/read-only states. Unassigned employees receive the manager-assignment instruction; unknown/stale evidence supplies no action.
6. Clock in to the baseline, interrupt a response, restart/resume and recover the same UUID. Clock out early or reject in the manager review flow; refresh/restart and verify the occurrence cannot reopen. Only a separately authorized extra permits a second occurrence.
7. Repeat extra clock-in with network loss/restart, then switch workspace/user/role while a response is delayed. Verify scope isolation and no stale state. Expired baseline recovery resolves history or remains blocked without a new occurrence POST.
8. Record a separate already-worked extra using workspace-local explicit offsets and past actual times. Confirm saved CONSUMED authorization and linked APPROVED attendance. Exercise overnight, New York fold offsets, missing spring-forward time and wrong device offsets.
9. Verify no automatic BLUE award/baseline substitution. Use existing Employee Performance → Grant extra effort and explicitly link the attendance only if approving BLUE separately.
10. Exercise a failed refresh after each successful mutation; verify canonical success and a separate refresh retry. Repeat at 320px, increased text scale, dark mode, keyboard/safe areas and long names.

## Verification

Implementation and initial static inspection completed before the verification invocations.

| Command | Exact outcome |
| --- | --- |
| First sandboxed `dart format .` | Stalled in the SDK cache lock acquisition loop; stopped with exit 1 before formatter output. A separate escalation explicitly requested new rerun authorization, as required by the sprint. |
| Approved outside-sandbox `dart format .` | Exit 0; 651 files inspected, 63 changed, 4.09 seconds. This also formatted 13 pre-existing ignored Dart compiler diagnostic files under `build/compiler-diagnostic` because the requested target was the whole workspace. |
| `flutter analyze` (one invocation) | Exit 1; 102 issues, 6.8 seconds. Included invalid String date comparisons and style diagnostics. |
| `flutter test` (one invocation) | Exit 1; 343 passed, 10 test-file loading failures, about 1 minute 13 seconds. The failures stemmed from a repository interface promotion/cast error in WorkPatternCubit. The sprint test file could not load, so its added tests did not execute. |

After analysis, date comparisons were corrected to `compareTo` and simple control-flow bodies received braces. During this cleanup, an explicit repository-interface cast was incorrectly removed; the test compiler detected that error. After the test run completed, the cast was restored with an explicitly typed nullable ExtraShiftRepository local. These post-check changes remain **unverified** by a new formatter/analyzer/test run. No clean verification claim is made. No analyzer/test rerun was performed, and no separate baseline command, APK build, `git diff --check` or explicit pub-get command was run.

The backend working tree is still clean at the same reviewed HEAD; pubspec/lock and the Firebase distribution workflow remain unchanged. An unrelated untracked `assets/images/Logo.png` appeared during work and was preserved.

Shared attendance history also now retains optional occurrence kind, assignment/authorization IDs, client UUID and manager-entry membership. Employee history and manager attendance details label EXTRA explicitly and display saved schedules with their recorded timezone. The manager details sheet scrolls for compact/scaled layouts.


## Changed file manifest

Deleted part-file paths below were moved into standalone files; the obsolete weekday-only dialog was removed. New files are included.

- `docs/flutter-assigned-shifts-sprint.md`
- `lib/app/parts/app_providers/private_app_providers_state.dart`
- `lib/core/di/dependency_registration.dart`
- `lib/core/error/api_error_parser.dart`
- `lib/core/error/api_exception.dart`
- `lib/core/error/parts/failure/failure.dart`
- `lib/core/utils/workspace_timestamp_input.dart`
- `lib/features/attendance/data/parts/attendance_repository/attendance_record_api.dart`
- `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart`
- `lib/features/attendance/presentation/widgets/parts/attendance_records_list/private_attendance_record_card.dart`
- `lib/features/employees/presentation/screens/employee_details_screen.dart`
- `lib/features/employees/presentation/screens/parts/employee_details_screen/private_employee_details_view.dart`
- `lib/features/fixed_shifts/data/api_fixed_shift_repository.dart`
- `lib/features/fixed_shifts/data/attendance_classification.dart`
- `lib/features/fixed_shifts/data/attendance_source.dart`
- `lib/features/fixed_shifts/data/confirmed_mutation_rejection.dart`
- `lib/features/fixed_shifts/data/eligible_shift_occurrence.dart`
- `lib/features/fixed_shifts/data/extra_authorization.dart`
- `lib/features/fixed_shifts/data/extra_authorization_page.dart`
- `lib/features/fixed_shifts/data/extra_shift_intent.dart`
- `lib/features/fixed_shifts/data/extra_shift_repository.dart`
- `lib/features/fixed_shifts/data/fixed_shift_dates.dart`
- `lib/features/fixed_shifts/data/fixed_shift_repository.dart`
- `lib/features/fixed_shifts/data/fixed_shift_repository_contract.dart`
- `lib/features/fixed_shifts/data/flexible_attendance.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/attendance_classification.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/attendance_source.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/eligible_shift_occurrence.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/fixed_shift_repository.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/flexible_attendance.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/pending_clock_in.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/shift_template.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/shift_template_input.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/shift_template_page.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/template_eligibility.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/work_pattern.dart`
- `lib/features/fixed_shifts/data/parts/fixed_shift_repository/work_pattern_history.dart`
- `lib/features/fixed_shifts/data/pending_clock_in.dart`
- `lib/features/fixed_shifts/data/preview_fixed_shift_repository.dart`
- `lib/features/fixed_shifts/data/saved_schedule.dart`
- `lib/features/fixed_shifts/data/shift_template.dart`
- `lib/features/fixed_shifts/data/shift_template_input.dart`
- `lib/features/fixed_shifts/data/shift_template_page.dart`
- `lib/features/fixed_shifts/data/template_eligibility.dart`
- `lib/features/fixed_shifts/data/work_pattern.dart`
- `lib/features/fixed_shifts/data/work_pattern_history.dart`
- `lib/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart`
- `lib/features/fixed_shifts/presentation/cubit/fixed_shift_mutation_result.dart`
- `lib/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/flexible_attendance_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/manager_templates_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/manager_templates_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/fixed_shift_mutation_result.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/flexible_attendance_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/flexible_attendance_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/manager_templates_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/manager_templates_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/work_pattern_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/parts/fixed_shifts_cubit/work_pattern_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/work_pattern_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/work_pattern_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/active_attendance_card.dart`
- `lib/features/fixed_shifts/presentation/widgets/active_template_selector.dart`
- `lib/features/fixed_shifts/presentation/widgets/assignment_form.dart`
- `lib/features/fixed_shifts/presentation/widgets/assignment_form_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/attendance_presentation.dart`
- `lib/features/fixed_shifts/presentation/widgets/eligibility_tile.dart`
- `lib/features/fixed_shifts/presentation/widgets/employee_fixed_shifts_screen.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_authorization_card.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shift_form.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shift_form_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shifts_section.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart`
- `lib/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/flexible_attendance_panel/private_active_attendance_card.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/flexible_attendance_panel/private_eligibility_tile.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/shift_templates_screen/private_template_editor_dialog_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/work_pattern_section/private_pattern_dialog.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/work_pattern_section/private_pattern_dialog_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/work_pattern_section/private_weekday_row.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/work_pattern_section/private_work_pattern_view.dart`
- `lib/features/fixed_shifts/presentation/widgets/shift_templates_screen.dart`
- `lib/features/fixed_shifts/presentation/widgets/weekday_row.dart`
- `lib/features/fixed_shifts/presentation/widgets/work_pattern_section.dart`
- `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart`
- `test/fixed_shifts_sprint_test.dart`
