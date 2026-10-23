# Personal task manager

Employees and managers open **Task manager** using the checklist icon beside the notification bell. Tasks are private to their account across accessible workspaces; creating a task associates it with the current workspace. This feature does not assign tasks to colleagues.

## Features and organization

- Create/edit a title (160 characters), details (5,000 characters), and a future date/time, up to 100 years ahead in the date picker. Complete, reopen, or permanently delete tasks. Open/completed lists are paginated; overdue tasks are highlighted.
- Responsive Arabic/English UI follows the app language and theme. Dates are displayed and entered in the device timezone, saved as UTC instants, and retain that instant when travelling. Deadlines have minute precision in the editor.
- The editor includes a duration from 1 to 10,080 minutes, with 5/15/25/45/60 minute shortcuts (25 minutes initially selected for a new task). Time selection uses [day_night_time_picker](https://pub.dev/packages/day_night_time_picker), with localized labels, the application theme, and separate date/time controls.
- Each card shows a live countdown **until the task's scheduled time**, rather than a manually started stopwatch. It derives the remaining time from the saved UTC deadline every second, so reopening/resuming the app restores the correct value. At the scheduled time it counts down the task duration, then shows that its time has ended. Completion stops the countdown; expiration does not automatically complete a task.
- Flutter code lives in `lib/features/tasks/{domain,data,application,presentation}`. The repository contract and reminder contract separate the API and native scheduler from state and widgets. `AppTaskCoordinator` binds account lifecycle and validated notification taps.
- NestJS code lives in `src/modules/personal-tasks`. Every operation scopes ownership to the authenticated profile and active workspace membership. Managers cannot read another person's personal tasks. Revision checks return 409 for conflicting edits/deletes. Profile/workspace deletion cascades to tasks and scheduling registrations.

## Deploy the backend before the app

In `E:\MY APPS\shiftly-backend`, configure the intended release database, review pending migrations, then run:

```powershell
npx prisma migrate status
npx prisma migrate deploy
npx prisma generate
npm run build
```

The task migrations are `20261024090000_personal_tasks`, `20261024100000_task_duration_and_advance_reminders`, and `20261024110000_task_hour_reminders`. The last migration adds the independent one-hour preference, scheduled instant and delivery receipt, plus version 3 native alarm coverage. Existing tasks retain their previous behavior until edited: no duration, day-before or hour-before reminder is added retroactively. `migrate deploy` also applies any older pending migrations; review those in the normal release process. These implementation checks did not apply migrations to a live database.

Deploy the backend with its existing authenticated API configuration. Server fallback uses `FIREBASE_SERVICE_ACCOUNT_JSON` and `PUSH_PROCESSOR_SECRET` in backend secrets. Run the existing authenticated-by-secret worker every minute:

```text
POST /api/v1/internal/push-processing?batchSize=50
x-shiftly-processor-secret: <server secret>
```

An external scheduler must actually call this endpoint; serverless hosting does not run a permanent timer. Scale scheduling/batches to traffic. The worker creates canonical task notification history even if FCM credentials are absent. Apply the database migration before routing worker invocations to the new backend.

Build/install a new mobile binary after deploying the API. Hot reload does not install Android manifest changes or native plugins. Android client Firebase configuration is already present locally; keep it out of Git. Follow [mobile push setup](push-notifications-setup.md) for release Firebase secrets, APNs and iOS configuration. This Windows workspace does not contain `ios/Runner/GoogleService-Info.plist`; iOS push still requires your real Firebase/APNs setup and a macOS build.

## How reminders work

1. Open Task manager on the phone and select **Enable reminders** using the settings icon in the reminder banner. Android requests notification access and **Alarms & reminders** access for precise scheduling. iOS requests notification permissions. This action also enables the existing mobile push registration when Firebase is available.
2. Native local alarms are scheduled on Android/iOS. They work without internet once scheduled and can fire while the application process is closed. Android boot receivers restore scheduled reminders after reboot. Force stopping the application, revoking permissions, device power restrictions, Focus/DND, and powering off the phone can prevent or delay alerts.
3. The nearest 60 future **alarm events** are scheduled, leaving room under iOS's 64 pending notification limit. One task can consume up to four slots: day-before, hour-before, due, and duration end. There is no short server-side scheduling horizon: later tasks stay in the database. Opening/resuming the app replenishes the native window; foreground reconciliation also runs every minute (every 30 seconds on the tasks page). Tasks outside the native window rely on server push until a phone sync schedules them.
4. Only successfully scheduled precise alarms are acknowledged per installation and task revision. The worker avoids FCM duplicates on that installation, while retaining in-app history and delivering to other registered devices. Approximate Android alarms keep FCM fallback enabled, so duplicates are possible. FCM itself is at-least-once; a network/crash retry can also duplicate delivery. Reconciliation reuses existing native alarm IDs. If withdrawing server acknowledgements fails, the phone preserves its current alarms and installs new ones only within the 60-alarm window, reports a sync warning, and retries; an acknowledgement outage does not erase working alarms.
5. The server atomically claims each due task revision, creates a deduplicated notification, and rechecks task existence, owner, membership, completion and revision before sending. Completed/deleted/rescheduled tasks invalidate stale queued pushes. An alarm is cancelled on the device after a successful mutation, even before the next list refresh.
6. Taps fetch the authenticated task before navigating. Another account's or an inaccessible/deleted task never opens. Task pushes can open a personal task from another active workspace without switching the selected workspace. Logout/account changes clear pending local task alarms.

The editor has independent **Remind me one day before** and **Remind me one hour before** switches, both initially enabled for new tasks. Choose both, either one, or neither. They target exactly 24 hours and 60 minutes before the task respectively, preserving the saved UTC instant. The hour notification says **Task in one hour: [title]** (Arabic on the native scheduler when Arabic is selected). If the selected lead time is already past when a task is created or rescheduled, no retroactive early notification is sent. A due-time alert remains enabled, and tasks with a saved duration also get a sound notification at `dueAt + durationMinutes`. These are standard OS notifications, not continuously ringing alarm-clock screens.

Each event has its own server receipt and deduplication identity. Editing time or duration recalculates dependent dates; completion/deletion invalidates all events. Disabling either early reminder cancels its future alarm without changing the other preference. Native acknowledgements suppress fallback only when **all** remaining events for that task revision fit in the native window. Partial coverage can produce duplicate local/push alerts, while leaving fallback available. Version 1 registrations suppress only due-time pushes; version 2 also covers day-before/end alerts. Only version 3 registrations suppress hour-before pushes, keeping fallback available for older app installations.

Native scheduling is the primary timing mechanism. The server fallback has scheduler/FCM/network latency; it cannot guarantee delivery at an exact second. Native exact alarms also remain subject to OS rules. Edits made from another device cannot cancel an alarm on an offline phone until it reconnects/syncs. Permission changes made outside the app are reflected on the next resume/sync. Browser task management works; browser background push is outside this mobile-focused release.

## Release acceptance on real devices

- Enable reminders, create a task a few minutes ahead, lock the phone, and verify the alert and sound while the app process is closed. Repeat offline after scheduling.
- Edit its time, complete it, and delete it separately; verify the old alarm is cancelled. Test reopening and long future dates, UTC offsets and daylight saving transitions.
- Create a five-minute task, verify the countdown until its start, then the remaining five minutes and the end notification. Close/reopen the app mid-countdown and confirm that time was not reset. Test the day-before reminder for a task saved more than 24 hours ahead, and ensure no late early reminder appears for one created within 24 hours.
- Test all four day/hour combinations, save and reopen the task, and verify that the selected settings persist. For an hour reminder, save a task more than an hour ahead; verify its alert at the task's UTC instant minus 60 minutes. Disable the hour reminder or change the task time, and verify that its old alert is cancelled. Repeat on an installation with an older app build to check server fallback.
- Restart Android, deny/revoke precise alarms, and verify permission status and approximate/fallback behavior. Test an iPhone using an appropriately signed build.
- Test two installations, a web edit, account logout/switch, and a tap after deletion. Confirm native+FCM deduplication on the scheduled phone and fallback on the other phone.
- Verify the worker scheduler runs in production, not only when an API mutation happens. Do not mistake passing mocks/native builds for proof of real FCM/APNs delivery.

Implementation references: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [Android alarm behavior](https://developer.android.com/develop/background-work/services/alarms), [FCM priority and delivery](https://firebase.google.com/docs/cloud-messaging/customize-messages/setting-message-priority).

## Local validation

Run the task/widget/native-channel regression suite with:

```powershell
flutter test test/tasks_feature_test.dart test/device_task_reminders_test.dart test/task_timing_test.dart
```

Coverage includes Arabic/English at mobile and desktop widths, the new time picker, task lifecycle, logout races, UTC offsets, preserving seconds when editing an overdue task, countdown transitions, all four event instants, every day/hour option combination, cancellation, native scheduling acknowledgements, registration outages, stable alarm IDs and the bounded native window. Native-channel mocks verify requests to the plugin, not OS delivery.

The disposable migration smoke test uses the backend's installed PGlite dependency and loads no application environment secrets:

```powershell
node scripts/verify-task-migration.cjs
```

It applies the task migration against minimal parent tables in an in-memory PostgreSQL instance and checks UTC timestamps, defaults, constraints, access restrictions and cascading deletion. It does not replace applying the full migration history to staging. Backend checks are `npm test`, `npm run test:e2e -- personal-tasks.e2e-spec.ts` and `npm run build` in the backend directory.

Initial implementation baseline on 2026-10-23: all 698 Flutter tests and 687 backend tests passed (two skipped). For the duration/countdown extension, all 23 focused Flutter tests and all 701 backend tests passed (two skipped) with `npm test -- --maxWorkers=2`; all 25 personal-task HTTP tests, Flutter analysis, backend build/lint, and the expanded disposable task migration smoke test passed. Regressions also verify replenishment when an event passes without a task revision change, and that a task within its duration is not labelled overdue. Real-device notification delivery, iOS compilation and production migration/worker deployment remain release checks.

Android debug APK compilation passed using `--dart-define-from-file=config/dev.json`; the artifact is `build/app/outputs/flutter-apk/app-debug.apk`. Standard web release compilation passed using `--dart-define-from-file=config/web.local.json`; the artifact is `build/web`. These existing local configuration files remain ignored. The web build reports existing `image` package incompatibilities in its optional Wasm dry run; the standard JavaScript build succeeds. Android also reports existing Kotlin-plugin migration advisories.

One-hour reminder extension: 31 focused Flutter tests, 54 backend task/push tests, all 32 personal-task HTTP tests and all five isolated PostgreSQL purge/migration tests passed. Backend build/lint and the expanded migration smoke test passed. The hour migration is additive; previous migration files remain unchanged.
