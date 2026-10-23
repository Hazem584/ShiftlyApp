# Platform status and administration

The platform console is a separate React project at `E:\MY APPS\shiftly-admin`. See its `README.md` for local startup and Vercel deployment. Backend API details are in `E:\MY APPS\shiftly-backend\docs\platform-control.md`.

Production composition in `AppProviders` wraps the router in `PlatformGate`; explicit preview/test composition remains independent of network configuration. The gate uses a separate unauthenticated Dio instance for `/platform/status` so service state can be read before login and during shutdown. It uses the normal authenticated client for `/platform/access` when a session exists.

The gate checks every 30 seconds and on resume, and observes API error responses for immediate `PLATFORM_UNAVAILABLE` and `ACCOUNT_SUSPENDED` feedback. The states are OPERATIONAL, MAINTENANCE, UPDATING, and DISABLED. Normal operation can display an administrator announcement. Blocked states show a custom title/message/support address, a retry button, and sign-out for a suspended account. Recovery follows the next successful status/access check.

The application tree remains mounted while hidden, preserving navigation. Initial status requires connectivity; later network failures retain the last known status. Server-side guards enforce access on newly authorized API requests, including older clients. Previously loaded data, in-flight work, pre-issued media URLs and delivered notifications cannot be recalled by this feature.

Release the backend endpoints before shipping this Flutter change. The migration is additive and defaults to OPERATIONAL. Set the server-side `PLATFORM_ADMIN_IDS` allowlist separately in each hosting environment. No administrative secrets are added to Flutter.

Validated with `flutter test test/platform_gate_test.dart test/authentication_api_repository_test.dart` (8 passing) and targeted Flutter analysis. Widget tests cover normal operation with an announcement, maintenance/recovery, account suspension/recovery, and clearing authentication after permanent account deletion.

Permanent account deletion now returns `ACCOUNT_DELETED` from the protected API while an old JWT remains unexpired. `PlatformGate` clears local authentication on that response, allowing the existing session coordinator to clear its session scopes. Backend deletion details and release requirements are in `shiftly-backend/docs/account-deletion.md`; the new migration must precede backend deployment. No administrative key belongs in Flutter. Already downloaded data on offline devices cannot be recalled remotely.
