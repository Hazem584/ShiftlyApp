# Flutter corrective sprint

Reviewed and actual initial HEAD: `682b1d0092fb89710f2a49421ff886e54403c5b7`. Initial working tree was clean.

## Behavior and causes

Attendance loads previously checked session generation alone, allowing a captured open record or pending intent to overwrite a later mutation. The cubit now checks a monotonically increasing operation/read revision at every asynchronous state boundary. Mutations invalidate earlier reads and refreshes. Duplicate loads share a future; repeated refresh requests invalidate the older read and coalesce into a subsequent load. Post-mutation eligibility reads retain canonical attendance and are revision guarded. Session changes reset ownership. Closed canonical attendance survives a refresh returning no current open record.

Extra create/recover/revoke previously unlocked before callbacks and reads, letting an older finally unlock another mutation. Each mutation now owns a unique token. Its lock lasts through persistence, POST/DELETE, validation, exact-intent cleanup, callback, and follow-up read. Only its owner can release it or emit its mutation state. Read requests additionally check generation and request identity. Recovery retains the saved employee target even if the selected employee changes. Callback/list failure preserves canonical success.

Historical source inspected: `0f5c585` v1 writer/reader and `394eebc` v2 writer/reader. Both persisted userId, workspaceId, membershipId, templateId, clientAttendanceId. v1 used a global key; v2 included all four scope/template fields in its key. Neither saved occurrence/date evidence. The previous sprint incorrectly treated every global v1 as unscoped and threw a generic error.

Legacy review is now a separate repository capability and state/UI model. Verified foreign ownership is excluded. Matching ownership is checked against authenticated `/attendance/me` history with the existing request ID, membership, workspace, and template. No legacy POST, UUID generation, migration, or deletion occurs. Confirmed records remain in their original storage as audit evidence and do not block a new shift. Missing, malformed, or unavailable evidence produces an explicit review card with a refresh action and support explanation, while v3 recovery remains separate. V3 cleanup compares request ID, exact payload, kind, and original date.

## Recovery limits

An unidentifiable global v1 remains on this device and conservatively blocks new clock-ins because its ownership cannot be established. Identifiable records with no canonical match cannot safely be replayed without occurrence evidence. Support must inspect retained evidence externally; this app has no legacy dismissal/review endpoint, and offers no manager-review action. Refresh only rechecks canonical history. No destructive unblock mechanism was introduced.

The clock-in DTO cannot pin operationalDate. Expired baseline recovery therefore remains retained and blocked; it can reconcile an existing canonical attendance, but cannot be POSTed against a later occurrence. The UI exposes the saved request ID and original date for support.

## Files

- `lib/features/fixed_shifts/data/api_fixed_shift_repository.dart`
- `lib/features/fixed_shifts/data/legacy_clock_in_repository.dart`
- `lib/features/fixed_shifts/data/legacy_clock_in_review.dart`
- `lib/features/fixed_shifts/presentation/cubit/flexible_attendance_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart`
- `lib/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart`
- `lib/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart`
- `lib/features/fixed_shifts/presentation/widgets/legacy_clock_in_review_card.dart`
- `test/fixed_shifts_sprint_test.dart`
- This report.

The mandatory whole-repository formatter also changed the existing sprint files below. These changes are formatting only, except `work_pattern_view.dart` and the attendance record card, which also received the analyzer's string-interpolation corrections:

- `lib/core/utils/workspace_timestamp_input.dart`
- `lib/features/attendance/presentation/widgets/parts/attendance_records_list/private_attendance_record_card.dart`
- `lib/features/fixed_shifts/data/extra_shift_intent.dart`
- `lib/features/fixed_shifts/data/fixed_shift_dates.dart`
- `lib/features/fixed_shifts/data/saved_schedule.dart`
- `lib/features/fixed_shifts/presentation/cubit/manager_templates_cubit.dart`
- `lib/features/fixed_shifts/presentation/cubit/work_pattern_cubit.dart`
- `lib/features/fixed_shifts/presentation/widgets/assignment_form_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shift_form_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shifts_section.dart`
- `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/shift_templates_screen/private_template_editor_dialog_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/shift_templates_screen.dart`
- `lib/features/fixed_shifts/presentation/widgets/work_pattern_section.dart`
- `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart`

## Regression cases

Completer-controlled attendance load vs clock-out, load vs canonical recovery, old post-mutation eligibility vs newer refresh, duplicate/queued refresh behavior, and current/storage/catalog/eligibility results after logout or workspace switching. Canonical success survives callback/refresh failure.

Both historical versions cover user/workspace/membership isolation and canonical reconciliation without POST or deletion. Ambiguous and failed storage reads remain review-required and preserved; failed history reconciliation retains raw evidence. Quarantine does not interfere with exact v3 payload/UUID recovery. Widget coverage verifies actionable review text without a replay action.

Manager tests hold create and revoke callbacks, exercise rapid create/recover/revoke, prevent old finally from unlocking a newer operation, reject old lists over newer uncertain recovery, preserve success after callback/read failure, retain saved target identity, and reject employee/workspace/user-switch responses. Existing contract fixture assertions were updated to include the required assignment template ID and complete employee summary.

## Verification

The required commands were each invoked exactly once after initial implementation. No earlier baseline or focused Flutter test commands were run, and none of these commands were rerun.

| Command | Result |
| --- | --- |
| `dart format .` | Exit 0; 654 files, 21 changed; formatter reported 3.39 seconds. |
| `flutter analyze` | Exit 1; 17 informational style diagnostics, no compiler errors or warnings; 39.5 seconds. |
| `flutter test` | Exit 1; 453 passed, 5 failed; runner duration 12:28. No test-file loading failures. |

All 17 analyzer diagnostics were corrected with string interpolation and null-aware map entries. Analysis and formatting were not rerun; these final corrections are unverified by those tools. The suite successfully loaded the previously failing test files. During the single test invocation, the legacy review widget fixture stalled because Dio's queued asynchronous work needs `tester.runAsync` in a widget test. That setup was corrected in source. Newly added race-test waiters were also corrected to check already-emitted failure state and await explicit submission Completers, avoiding subscriptions after synchronous emissions. The invocation used the earlier source snapshot; these later test-harness corrections remain unverified. The final tree is not claimed to pass formatting, analysis, or tests.

The five failures were all timeouts in the new regression fixtures:

- Legacy review widget: ten-minute timeout awaiting queued Dio work under the widget test clock.
- Old extra finally versus newer mutation: 30-second timeout subscribing after the synchronous intent emission.
- Employee-switch, workspace-switch, and user-switch extra tests: the same 30-second late-subscription timeout in each case.

The executed attendance stale-load/recovery/eligibility/coalescing tests, both historical-version isolation/reconciliation tests, retained v3 UUID/payload tests, rapid create/revoke callback tests, old-list versus uncertain recovery test, and callback/refresh-failure canonical-success tests passed. The 453 passing tests apply to the tested snapshot, not to the unverified final corrections.

A final cleanup review also removed the asynchronous gap between extra-intent ownership comparison and starting removal, and added a synchronous recheck of every v3 identity/payload field after its awaited decode. This prevents an old cleanup from removing a replacement record. This last source correction is also unverified by the final commands.

## Manual sequence

1. Clock in; hold/slow eligibility refresh, clock out, then let refresh finish. Attendance must stay closed.
2. Simulate an uncertain clock-in and restart; recover while a schedule refresh is pending. Confirm the same request ID and canonical attendance; verify expired baseline evidence cannot become a later occurrence.
3. As manager, rapidly create/recover/revoke extras while callback/network work is delayed. Only the first owned action submits; canonical success remains visible after a failed refresh.
4. Switch selected employee, workspace, user, and log out with reads/mutations pending. Old responses must not update the new session or unlock its operation. Check identifiable legacy records under their owner and another user; ambiguous records must remain visible for review.

Backend, CI/Firebase workflow, dependencies, database, deployment, branches, and Git history were not changed. No APK builds, SQL, migrations, or `git diff --check` were run.
