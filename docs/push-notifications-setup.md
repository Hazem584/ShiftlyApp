# Mobile push notifications

The Flutter receiver and NestJS device registration/delivery pipeline are implemented. Actual delivery requires the configuration below; local tests do not send real FCM messages.

## Android

- Use the existing Firebase Android registration for `com.example.shiftly`. Local configuration belongs in the ignored `android/app/google-services.json`; it must be client configuration, never a service-account private key.
- For tester release builds, add the complete client JSON to the repository secret `SHIFTLY_FIREBASE_ANDROID_CONFIG_JSON`. The distribution workflow restores and validates it before compiling. Without it, the APK still builds, but mobile push shows unavailable.
- The Google Services Gradle plugin is applied only when this file exists. Android 13+ notification permission is requested only when the user enables Mobile notifications in the Notifications screen. The `shiftly_updates` channel and a white notification bell are configured natively.
- Test on a device/emulator with Google Play services. Rebuild/install after adding native configuration; hot reload cannot activate it.

## iOS

- Register the matching `com.example.shiftly` iOS app in the same Firebase project. Add the downloaded `GoogleService-Info.plist` to the Runner target/resources through Xcode, or configure equivalent FlutterFire initialization. No iOS project configuration is fabricated in this repository.
- Runner has APNs entitlements, Background fetch and Remote notifications modes. Enable Push Notifications on the Apple App ID and use an appropriate signing profile. Xcode export/signing must supply the correct production APNs entitlement for release distribution.
- Upload an APNs authentication key to Firebase. Keep method swizzling enabled. The receiver checks that an APNs token exists before requesting an FCM token; if it is not ready, the settings screen offers a retry and resume attempts registration again.
- Native iOS compilation and delivery must be verified on macOS/Xcode and a signed device build.

See [Firebase's platform setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) and [foreground/background/tap handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages). Background and terminated delivery uses an FCM `notification` + `data` message displayed by the OS. No unsupported data-only background execution is claimed. A force-stopped Android app must be opened again before messages can work; delivery is also subject to OS settings/network availability.

## NestJS backend

Changes are in `E:\MY APPS\shiftly-backend`:

1. Apply the checked-in migration `20261010120000_add_push_delivery` through the normal release process; Prisma client generation is a local build step and does not apply the migration.
2. Set `FIREBASE_SERVICE_ACCOUNT_JSON` in the **backend's server-only environment secrets**, for a service account with Cloud Messaging API Admin access to this Firebase project. The App Distribution service account is a separate credential and must have the required role if intentionally reused. Enable FCM HTTP v1. Never copy this credential into Flutter or `google-services.json`.
3. Set a separate `PUSH_PROCESSOR_SECRET` of at least 32 characters in backend secrets.
4. Schedule a POST to `/api/v1/internal/push-processing` every minute with header `x-shiftly-processor-secret`. Default batch size is 10, maximum 50; configure schedule/runtime capacity for event volume. This task does not deploy hosting, apply a live migration, create a scheduler, or alter account secrets.

The authenticated client uses `PUT /notifications/devices` with `{installationId, token, platform}` and idempotent `DELETE /notifications/devices/{installationId}`. `GET /notifications/{notificationId}` fetches the owned canonical record before navigating. Backend identity always comes from the authenticated session, never a caller-supplied profile ID.

Committed notifications for shifts, attendance, leave and other existing events feed the durable per-device delivery queue. The worker also creates chat notices for unread active group recipients, excluding the sender, and reminders for canonical dated shifts starting within 15 minutes. It rechecks group/workspace membership, device ownership, and cancellation/rescheduling before sending. Recurring template reminders require a canonical expected-occurrence feed and are not inferred from mutable template settings.

The worker uses atomic leases, a source deduplication key, per-device delivery state, exponential backoff, at most five attempts and 24-hour expiry. History existing before the migration is marked processed. Sending is at-least-once; a crash between FCM acceptance and the database acknowledgement may duplicate an OS alert. See [FCM HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api).

## App behavior and validation

- Mobile notifications are opt-in, saved per account on this installation. No permission prompt appears at startup. Unsupported desktop platforms continue normally; missing native Firebase configuration does not block sign-in or the rest of the app.
- Foreground pushes refresh notifications/dashboard and fetch the authenticated canonical record to show its title/message with a View action. Background/terminated taps wait for a validated session. Data payloads contain only notification/workspace/recipient identifiers; arbitrary URLs/routes are ignored.
- The active account and workspace must match the push. Cross-workspace notifications do not automatically switch workspaces. The canonical notification and destination are fetched through existing authenticated APIs before opening shifts, attendance, leave or the chat conversation.
- Logout/opt-out invalidates the FCM token even when the backend revocation request is offline. Token refresh re-registers the device. Revoked OS permission disables the active registration; ordinary refresh never triggers a permission prompt.
- Lock-screen text includes the event and workspace, chat sender/group/message preview, or attendance shift/time. Preview text is bounded; deleted chat messages are skipped. These details are visible wherever the OS displays notifications. Tokens/keys/provider responses are not logged.

Successful chat, attendance, shift and leave mutations trigger a bounded delivery pass
after the business transaction commits. The pass is awaited so a serverless instance
does not suspend before dispatch; failures preserve the successful action response.
This can extend API response time while Firebase is contacted. Newly enqueued
deliveries are eligible in the same pass, removing the second scheduler interval.
Keep the one-minute cron for retries, backlog and reminders. Device/network/Firebase
conditions can still delay delivery; immediate dispatch is not a delivery guarantee.

Verify on real configured devices: foreground, background, cold-start tap, denied permission, token rotation, opt-out, logout/account switching, stale/deleted destination, and another workspace's notice. On the backend verify concurrent workers, retries, invalid-token removal, group removal, and reminder cancellation/rescheduling. Unit tests cover these rules with mocks, not live Firebase/Apple delivery.
