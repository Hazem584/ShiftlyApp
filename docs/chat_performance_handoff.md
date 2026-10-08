# Chat performance, private caching and instant sending

Reviewed Flutter HEAD `6b308cf8fade7fe610683ae708c4c9b515856408` (Master) and read-only backend HEAD `74768e3d2af26264bc5435da2e15e77964a9b04d` (main). Each repository had one worktree and was clean on entry. No applicable AGENTS.md was found. No backend edits, migrations, builds, commits, pushes, deployments or Git history changes were made.

## Findings and backend contracts

- Every new conversation Cubit fetched the latest page and discarded its previous instance's history. Realtime already had 300 ms debounce and a queued refresh; these remain canonical invalidations rather than full-history loads.
- Both image creation and voice source switching fetched fresh signed URLs. Image.network used the changing signed URL as identity; fullscreen fetched the same image separately. Voice already had one conversation player, which is preserved and now has shared source-selection generations and file leases.
- Text awaited the server with a globally disabled composer and no durable bubble. Location created a new UUID on every submission. Media had immediate preview but only memory jobs; closing the route cancelled tracked uploads, including uncertain finalizations.
- Backend `chat.service.ts:listMessages` returns newest first with strict older-than `(createdAt, id)` cursor boundaries, default 30/max 100. There is no messages-since endpoint. Cached pages retain the server-provided cursor, separately from subsequent latest refreshes. Disjoint refreshes retain valid displayed history and expose a gap until older canonical pages overlap the retained boundary.
- `sendMessage` first checks active group access and archive status, then checks `(senderMembershipId, clientMessageId)` before checking upload consumption/expiry. Retrying an immutable payload with its original UUID can recover canonical text, location or media confirmation. Archive rejection happens before idempotent recovery; archived uncertain operations may need discovery in canonical history.
- Upload initiation has no idempotency key or authorization recovery GET. IMAGE supports JPEG/PNG/WebP up to 5 MiB. VOICE supports the existing five MIME types, up to 10 MiB and 10 minutes. Persist uploadId, never its signed URL/token. An interrupted PUT is safely cancelled/reinitialized only before any finalization attempt. An uncertain finalization retains uploadId and retries that same message operation without DELETE.

## Persistence, limits and privacy

Added [Sembast 3.8.11](https://pub.dev/packages/sembast): pure Dart transactional file persistence, bounded page records, ordered LRU/outbox queries, no SharedPreferences message database or native SQLite installation. Added [crypto 3.0.7](https://pub.dev/packages/crypto) as a direct dependency for SHA-256 media corruption fingerprints; it was already transitive.

Services are registered and owned by GetIt. The existing ChatGroupsCubit/session coordination establishes in-memory grants from canonical group lists; details lookup validates unknown group IDs before cache use. Grants are not persisted. Cached identity alone never authorizes offline access. Session generation/workspace changes hide old content and reject old callbacks. Confirmed denial/removal immediately revokes access, cancels signed transfers, clears decoded images/player sources and purges the scoped records/files. Logout/user changes purge the former user, with a cleanup barrier before private storage reads/writes; startup removes records of other users and orphan files from this cache's dedicated directory.

Defaults are constructor-configurable:

| Resource | Default | Cleanup |
| --- | --- | --- |
| Canonical message pages | 500 stored message entries per conversation, 40 conversations, 30 days since access | Transactional page LRU; evict whole coverage pages without inventing cursors |
| Downloaded media | 128 MiB, 14 days since access | LRU, completed validated files only, maximum two transfers |
| Durable outbox | 100 unresolved operations | Never age-evicted; media can occupy up to roughly 1 GiB at the maximum voice payload size |
| Outgoing network submissions | One shared FIFO slot | Other messages remain editable and accepted into the outbox |

App support `private-chat-v1` contains the database and opaque UUID file names. Only canonical rendering fields, stable client IDs, payload metadata, non-secret upload IDs and relative owned file names are stored. Sender signed/avatar URLs, access tokens and upload authorizations are excluded. This is private app storage, not encryption at rest or protection against a compromised device.

Media resolves only when a bubble is built or played; history is not eagerly downloaded. A separate bearer-free Dio uses HTTPS without redirects, streams to a temporary file, enforces size and canonical MIME/signature metadata, then atomically renames and fingerprints it. Concurrent requests share a transfer. Cached hits check presence, metadata and fingerprint. Storage 401/403 refreshes the URL at most once. Active displayed images and playback files are pinned; unresolved outbox files are outside media eviction. Playback completion releases deferred file deletion. Clear-cache controls and approximate MiB are available in the chat list for both roles and in Manager Profile; active files remain protected.

## Outbox and restart semantics

The existing conversation send pipeline is refactored into a single shared model for TEXT/IMAGE/VOICE/LOCATION. Normalize and validate, copy media into owned storage, durably insert the operation, then show the keyed pending bubble and return acceptance to clear the composer. No optimistic sent acknowledgement or delivery/read ticks are added. Storage failure retains text or prepared media for retry.

Each operation keeps one UUID-v4 and immutable payload. Queued, sending/uploading/finalizing, failed and uncertain states are explicit. Canonical ID/client ID dedup removes pending only on canonical confirmation. Retryable API network/timeouts/5xx have one additional idempotent attempt after 350 ms; otherwise recovery is manual. Signed PUT/initiation are not blindly retried. Duplicate retries of one operation are suppressed. Safe cancel is allowed only for queued/failed never-submitted operations; uncertain messages cannot be discarded as if uncommitted.

Route close cancels local signed transfers but preserves outbox entries. Restart restores queued work only after current authorization and a successful canonical page fetch; interrupted/uncertain work waits for manual retry. A non-secret upload ID permits finalization recovery without persisting a signed authorization. Canonical confirmations are also merged into an existing cached latest window. If the queue is full or persistence fails, acceptance fails and input remains available.

## Verification and measurement

New local tests cover delayed cached opening, retained background failure, canonical merge/cursors/gaps, immediate pending types, rapid acceptance, capacity failure, stable UUID/lost response/duplicate retry, disk restart without persisted authorization grants, uncertain media recovery, archived scopes, denial/stale callbacks, user/workspace isolation, shared media transfers, expiry bounds, interrupted/corrupt files, concurrency cancellation, LRU/pins and outbox playback protection. Existing realtime and viewport anchoring/new-message tests remain part of the full suite. Existing media tests now check serial submission and explicit uncertain status.

Each requested command was executed exactly once:

| Command | Actual result |
| --- | --- |
| `dart format .` | Exit 0; 618 files processed, 34 changed, 3.96 seconds |
| `flutter analyze` | Exit 1; 61 diagnostics: 1 error, 18 warnings, 42 infos; 9.5 seconds |
| `flutter test` | Exit 1; 391 passes, 7 failing tests; approximately 40 seconds |

Analysis exposed an unsupported Dio `CancelToken.throwIfCancellationRequested` call, protected `emit` calls from an extension, obsolete pending-widget/import warnings and missing braces. These were corrected **before** the test run, which compiled and executed the suite. Analysis and formatting were not repeated.

The seven test failures were:

1. `chat_cache_outbox_test`: cached reopen/background failure — the fixture completed an error before the delayed fake API attached its listener.
2. `chat_cache_outbox_test`: older pages/cursor/merge — shared in-memory database name contaminated fixture state across tests.
3. `chat_cache_outbox_test`: lost response/stable UUID — the same fixture contamination left another test's canonical messages.
4. `chat_cache_outbox_test`: restart uncertain media — the same fixture contamination exposed cached loading state before restore finished.
5. `chat_media_integration_test`: voice pending UI — 21 px horizontal voice-row overflow.
6. `chat_cache_outbox_test`: four pending types — the same voice overflow plus a non-scrollable fixture column overflow.
7. `manager_performance_widget_test`: employee target/compact scaled controls — existing Manager Performance layout overflows; this sprint does not change that implementation.

**Unverified post-check changes:** unique in-memory database paths, explicit fake-request synchronization, a scrollable pending fixture, flexible pending-voice label, rejection of stale authorization/cache revisions, database compaction after privacy purge, and preserving the original gap boundary across successive disjoint refreshes while distinguishing initial page coverage from optimistic sends. These fixes were inspected but **not rerun through any of the three commands**, per the requested one-run limit. The tree is not claimed to have clean final analysis or passing final tests. The unrelated Manager Performance failure remains.

The actual controlled fixture output in that test run was `cold_ms=89 warm_ms=4 cold_urls=1 cold_downloads=1 warm_extra_urls=0 warm_extra_downloads=0`. This was a local 80 ms delayed repository and injected media adapter, not a production/device benchmark. That measurement assertion passed; the fixture isolation was subsequently corrected and not remeasured. Both cold and warm openings still perform a canonical background page request. Aggregate measurements contain no private message text, signed URLs or attachment paths. Full local command output is retained in ignored `.chat-format.log`, `.chat-analyze.log` and `.chat-test.log`.

## Remaining platform/contract limits

- The file-backed cache targets mobile and desktop, where this app already uses dart:io/path_provider; no web/IndexedDB implementation is added.
- Realtime membership/group invalidations depend on existing publication/RLS configuration. No cloud configuration is changed. Open-chat details are additionally checked every 30 seconds while resumed and on resume. Confirmed denial is immediate; detection during disconnected operation is not instantaneous.
- Existing API repository GET/POST requests do not expose request cancellation tokens. Scope generations reject their late results; signed Storage transfers are physically cancelled. Server work already accepted can still finish.
- No backend delivered/read acknowledgement, global delivery ordering, upload initiation idempotency, or always-online guarantee is claimed. No production timing or device playback verification is claimed.
- Pending voice playback and local image decoding still require device/manual checks. A prepared recording that could not be durably accepted is retained while the screen is open, then removed on scope loss/disposal; it is not falsely advertised as a restart-safe accepted operation.

## Manual regression

1. Open an authorized conversation with text, images and voice; confirm chronological layout and latest positioning.
2. Close and reopen it. Cached history should appear before refresh completes; previously rendered/played media should reuse local files without another URL/download request.
3. Scroll into older history and receive messages. Keep the anchor and use the existing new-message indicator. Load a reported gap and verify older pagination resumes its prior boundary.
4. Send text rapidly. Each accepted operation clears its own input, appears immediately, and confirms once while newer input remains editable.
5. Throttle networking and send image/voice. Check local preview/duration, pending local voice playback, progress and continued text composition.
6. Interrupt a PUT, then retry. Separately lose a finalization response after server commit; retry must use the same UUID/uploadId and must not DELETE that uncertain upload or duplicate its message.
7. Restart with queued and uncertain operations. Reauthorize the same group; known queued entries resume only after canonical connectivity, uncertain entries require Retry.
8. Expire a signed URL and verify one bounded refresh. Lower configured limits; verify LRU eviction, corruption/missing-file recovery and active playback protection. Clear media cache from chat settings.
9. Remove the user's group membership while chat is open. On canonical/realtime/periodic detection, hide the entire conversation, stop playback, cancel transfers and purge this group.
10. Logout/login as another user, including while downloads and POSTs are in flight. No former user's history, prepared media or pending state may flash; newer user data must survive former-user cleanup.
11. Open an archived group. History remains readable; sends and queued automatic replay are disabled. Uncertain confirmation remains honest if the archive contract prevents retry.
12. Verify pending-only empty conversations, cached openings, canonical replacements, older-page loading and downloads have no full-screen send spinner or scroll jumps.



## Changed files

- `docs/chat_performance_handoff.md`
- `lib/core/di/dependency_registration.dart`
- `lib/features/chat/data/cache/chat_cache_database.dart`
- `lib/features/chat/data/cache/chat_cache_scope.dart`
- `lib/features/chat/data/cache/chat_media_cache.dart`
- `lib/features/chat/data/cache/chat_message_cache.dart`
- `lib/features/chat/data/cache/chat_message_codec.dart`
- `lib/features/chat/data/outbox/chat_outbox_coordinator.dart`
- `lib/features/chat/data/outbox/chat_outbox_operation.dart`
- `lib/features/chat/data/outbox/chat_outbox_storage.dart`
- `lib/features/chat/data/parts/chat_realtime/supabase_chat_realtime.dart`
- `lib/features/chat/presentation/chat_playback_coordinator.dart`
- `lib/features/chat/presentation/cubit/chat_conversation_cubit.dart`
- `lib/features/chat/presentation/cubit/chat_group_details_cubit.dart`
- `lib/features/chat/presentation/cubit/chat_groups_cubit.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/chat_conversation_cubit.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/chat_conversation_state.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/chat_outbox_pipeline.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/chat_upload_state.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/pending_chat_media_type.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/pending_chat_message.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/private_media_job.dart`
- `lib/features/chat/presentation/cubit/parts/chat_group_details_cubit/chat_group_details_cubit.dart`
- `lib/features/chat/presentation/cubit/parts/chat_groups_cubit/chat_groups_cubit.dart`
- `lib/features/chat/presentation/screens/chat_groups_screen.dart`
- `lib/features/chat/presentation/screens/chat_screen.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/chat_screen.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/pending_media_bubble.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_chat_view_state.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_full_screen_image.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_message_bubble.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_pending_text_bubble.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_remote_image_state.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_voice_message.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_voice_message_state.dart`
- `lib/features/chat/presentation/widgets/chat_cache_settings_tile.dart`
- `lib/features/chat/presentation/widgets/messages/parts/shiftly_chat_message_list/private_shiftly_chat_message_list_state.dart`
- `lib/features/chat/presentation/widgets/private_chat_cache_settings_tile_state.dart`
- `lib/features/dashboard/presentation/screens/parts/employee_dashboard_screen/private_employee_dashboard.dart`
- `lib/features/manager_performance/data/api_manager_points_repository.dart`
- `lib/features/manager_performance/data/manager_points_repository.dart`
- `lib/features/manager_performance/presentation/cubit/manager_performance_cubit.dart`
- `lib/features/notifications/presentation/screens/parts/notifications_screen/private_notification_navigator.dart`
- `lib/features/points/presentation/widgets/points_achievements.dart`
- `lib/features/profile/presentation/screens/parts/profile_screen/private_profile_screen_state.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/chat_cache_outbox_test.dart`
- `test/chat_media_integration_test.dart`
- `test/chat_sprint1_test.dart`
- `test/manager_performance_widget_test.dart`

The dashboard, Manager Performance, notifications navigator, points achievements and Manager Performance test changes above are formatting-only results of the explicitly requested repository-wide formatter. Existing rejection dialog/controller fixes remain intact.
