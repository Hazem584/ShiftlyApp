# Personal task manager

Employees and managers open **Task manager** using the checklist icon beside the notification bell. Tasks are private to their account across accessible workspaces; creating a task associates it with the current workspace. This feature does not assign tasks to colleagues.

## Features and organization

- Create/edit a title (160 characters), details (5,000 characters), and a future date/time, up to 100 years ahead in the date picker. Complete, reopen, or permanently delete tasks. Open/completed lists are paginated; overdue tasks are highlighted.
- Responsive Arabic/English UI follows the app language and theme. Dates are displayed and entered in the device timezone, saved as UTC instants, and retain that instant when travelling. Deadlines have minute precision in the editor.
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

The new migration is `20261024090000_personal_tasks`. `migrate deploy` also applies any older pending migrations; review those in the normal release process. These implementation checks did not apply migrations to a live database.

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
3. The nearest 60 future tasks are scheduled, leaving room under iOS's 64 pending notification limit. There is no short server-side scheduling horizon: later tasks stay in the database. Opening/resuming the app replenishes the native window; foreground reconciliation also runs every minute (every 30 seconds on the tasks page). Tasks outside the native window rely on server push until a phone sync schedules them.
4. Only successfully scheduled precise alarms are acknowledged per installation and task revision. The worker avoids FCM duplicates on that installation, while retaining in-app history and delivering to other registered devices. Approximate Android alarms keep FCM fallback enabled, so duplicates are possible. FCM itself is at-least-once; a network/crash retry can also duplicate delivery. Reconciliation reuses existing native alarm IDs. If withdrawing server acknowledgements fails, the phone preserves its current alarms and installs new ones only within the 60-alarm window, reports a sync warning, and retries; an acknowledgement outage does not erase working alarms.
5. The server atomically claims each due task revision, creates a deduplicated notification, and rechecks task existence, owner, membership, completion and revision before sending. Completed/deleted/rescheduled tasks invalidate stale queued pushes. An alarm is cancelled on the device after a successful mutation, even before the next list refresh.
6. Taps fetch the authenticated task before navigating. Another account's or an inaccessible/deleted task never opens. Task pushes can open a personal task from another active workspace without switching the selected workspace. Logout/account changes clear pending local task alarms.

Native scheduling is the primary timing mechanism. The server fallback has scheduler/FCM/network latency; it cannot guarantee delivery at an exact second. Native exact alarms also remain subject to OS rules. Edits made from another device cannot cancel an alarm on an offline phone until it reconnects/syncs. Permission changes made outside the app are reflected on the next resume/sync. Browser task management works; browser background push is outside this mobile-focused release.

## Release acceptance on real devices

- Enable reminders, create a task a few minutes ahead, lock the phone, and verify the alert and sound while the app process is closed. Repeat offline after scheduling.
- Edit its time, complete it, and delete it separately; verify the old alarm is cancelled. Test reopening and long future dates, UTC offsets and daylight saving transitions.
- Restart Android, deny/revoke precise alarms, and verify permission status and approximate/fallback behavior. Test an iPhone using an appropriately signed build.
- Test two installations, a web edit, account logout/switch, and a tap after deletion. Confirm native+FCM deduplication on the scheduled phone and fallback on the other phone.
- Verify the worker scheduler runs in production, not only when an API mutation happens. Do not mistake passing mocks/native builds for proof of real FCM/APNs delivery.

Implementation references: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [Android alarm behavior](https://developer.android.com/develop/background-work/services/alarms), [FCM priority and delivery](https://firebase.google.com/docs/cloud-messaging/customize-messages/setting-message-priority).

## Local validation

Run the task/widget/native-channel regression suite with:

```powershell
flutter test test/tasks_feature_test.dart test/device_task_reminders_test.dart
```

Coverage includes Arabic/English at mobile and desktop widths, task lifecycle, logout races, UTC offsets, preserving seconds when editing an overdue task, native scheduling acknowledgements, registration outages, stable alarm IDs and the bounded native window. Native-channel mocks verify requests to the plugin, not OS delivery.

The disposable migration smoke test uses the backend's installed PGlite dependency and loads no application environment secrets:

```powershell
node scripts/verify-task-migration.cjs
```

It applies the task migration against minimal parent tables in an in-memory PostgreSQL instance and checks UTC timestamps, defaults, constraints, access restrictions and cascading deletion. It does not replace applying the full migration history to staging. Backend checks are `npm test`, `npm run test:e2e -- personal-tasks.e2e-spec.ts` and `npm run build` in the backend directory.

Verified on 2026-10-23: Flutter analysis passed; all 698 Flutter tests passed; 687 backend unit tests passed (two skipped); all 17 personal-task HTTP tests passed; backend build and lint passed; the disposable task migration smoke test passed. Real-device notification delivery, iOS compilation and production migration/worker deployment remain release checks.

Android debug APK compilation passed using `--dart-define-from-file=config/dev.json`; the artifact is `build/app/outputs/flutter-apk/app-debug.apk`. Standard web release compilation passed using `--dart-define-from-file=config/web.local.json`; the artifact is `build/web`. These existing local configuration files remain ignored. The web build reports existing `image` package incompatibilities in its optional Wasm dry run; the standard JavaScript build succeeds. Android also reports existing Kotlin-plugin migration advisories.
