# Access & Workspaces design implementation

## Baseline and scope

- Repository: Shiftly Flutter application.
- Initial HEAD: `6afc56aef4adde4b7952460e91023d1279837f70`.
- Initial worktree: clean. No branch change, commit, push, deployment, backend or native-platform changes.
- Design file: **New File 1**, ID `542abcb8-15f9-80f7-8008-e09cb0633f55`.
- Page: **Shiftly Redesign / Access and workspaces**, ID `a1ffe3ad-97e8-8098-8008-e09e4a70ce21`.
- Source hierarchy, shape geometry/styles, component metadata, local library/tokens, and rendered PNG references were read through Penpot MCP. Penpot was not modified.

## Frame mapping

All Flutter paths below are relative to the application repository. Main presentation directory: `lib/features/auth/presentation/`.

| Penpot frame | ID | Flutter implementation |
| --- | --- | --- |
| A02 Restoring session | a1ffe3ad-97e8-8098-8008-e09ef6edc145 | widgets/access_session_loading.dart; screens/session_status_screen.dart |
| A06 Sign in | a1ffe3ad-97e8-8098-8008-e09e68bb8c54 | screens/login_screen.dart |
| A06-Dark Sign in | 3c6bc856-584c-8060-8008-e14ab80a437f | screens/login_screen.dart; design/access_theme.dart |
| A06-AR Sign in RTL | 3c6bc856-584c-8060-8008-e14a95126e57 | screens/login_screen.dart; access_translations.dart |
| A07 Create account | a1ffe3ad-97e8-8098-8008-e09ef9e6e402 | screens/register_screen.dart |
| A08 Verify email | a1ffe3ad-97e8-8098-8008-e09efb3e8c70 | screens/email_verification_screen.dart |
| A09 Your profile | a1ffe3ad-97e8-8098-8008-e09efce2bb57 | screens/profile_setup_screen.dart |
| A10 Choose workspace | a1ffe3ad-97e8-8098-8008-e09efdf20f1d | screens/workspace_selection_screen.dart |
| A11 Create workspace | a1ffe3ad-97e8-8098-8008-e09efffbda83 | screens/create_workspace_screen.dart |
| A12 My invitations | a1ffe3ad-97e8-8098-8008-e09f017d47f1 | screens/my_invitations_screen.dart |
| A13 Invitation details | a1ffe3ad-97e8-8098-8008-e09f029efa45 | screens/invitation_details_screen.dart |
| A14 Join with token | a1ffe3ad-97e8-8098-8008-e09f042f9281 | screens/join_workspace_screen.dart |
| A15 Session expired | a1ffe3ad-97e8-8098-8008-e09f058ca242 | widgets/access_expired_view.dart, shown on existing /login route |
| A16 Offline startup | a1ffe3ad-97e8-8098-8008-e09f063b57bf | screens/session_status_screen.dart |
| A17 Workspace unavailable | a1ffe3ad-97e8-8098-8008-e09f076d9d17 | widgets/workspace_unavailable_view.dart, shown on existing /workspaces route |
| A18 Service unavailable | a1ffe3ad-97e8-8098-8008-e09f08a0f95c | screens/session_status_screen.dart |
| Workspace switching | Derived from A10 | widgets/workspace_switcher_sheet.dart; workspace_membership_chooser.dart |

Native splash A01, onboarding A03–A05, app update A19/A19b, dashboards, chat, tasks, reports, main profile and platform admin are outside this sprint.

## Tokens and components

Reference viewport: 390 × 844. Page inset: 24. Input height: 52–56; radius: 12; border: 1. Button minimum height: 52, radius: 14. Access list cards: radius 16, padding 16. Frame geometry takes precedence over generic foundation radius 20.

Light: background #F7F8FC, surface #FFFFFF, ink #17213C, muted #657087, line #E1E5EF, primary #4338CA, notice #ECEBFF.
Dark sign-in reference: background #101426, surface #1C233A, ink #F2F4FC, muted #B2BDD4, line #36415C, primary #B1A7FF. Dark notice/error treatments are derived semantic variants; inactive dark library tokens do not resolve.

Typography: Inter Tight 400/500/600/700; display 38, section 22, body 16, supporting 14; line height 1.25, letter spacing 0. Arabic: Noto Sans Arabic, display 32; body line height 1.4 for legibility.

Shared components live in `design/`: AccessTheme, AccessTokens, AccessPage, AccessField, AccessAction, AccessNotice, AccessTile, AccessBrand, AccessIcon/AccessIconPainter. Styles are scoped to access routes and switching sheets, preserving the global theme and stored language/appearance preferences. Existing GetIt, Bloc/Cubit, GoRouter, shared Dio, repositories and SessionCoordinator remain authoritative.

## Assets and intentional logo override

The approved application asset **assets/images/shiftly-mark.png** is reused via existing **lib/core/widgets/brand_logo.dart**. Its pixels, proportions and colors are unchanged. No Penpot logo was exported.

Original design SVGs are preserved under `assets/access/icons/`. Their exact normalized path commands are rendered by AccessIconPainter using Flutter Canvas, with the reference 1.8 stroke and theme-aware semantic colors. This avoids a new dependency, keeps vectors sharp and mirrors only the back arrow in RTL.

| Icon | Penpot source shape |
| --- | --- |
| back.svg | a1ffe3ad-97e8-8098-8008-e09efb7d0057 |
| file.svg | a1ffe3ad-97e8-8098-8008-e09efc3b3a20 |
| user.svg | a1ffe3ad-97e8-8098-8008-e09efdb842f3 |
| work.svg | a1ffe3ad-97e8-8098-8008-e09efee06ea3 |
| plus.svg | a1ffe3ad-97e8-8098-8008-e09effc5f54b |
| clock.svg | a1ffe3ad-97e8-8098-8008-e09f03689cef |

Fonts and SIL Open Font License notices: `assets/access/fonts/`.
Sources: https://github.com/google/fonts/tree/main/ofl/intertight and https://github.com/google/fonts/tree/main/ofl/notosansarabic.
No font fallback or new package is required.

## Behavior and differences

- Credentials, token ownership, persisted workspace selection, role routing and membership revalidation continue through existing services. The public access forms remain mounted during current-user loading and recoverable failure so entered values survive; protected role routes are still guarded.
- Workspaces and invitations use dedicated screens rather than a dense combined form. Create/token controllers live in mounted State and are disposed after their route finishes its transition. Duplicate operations are blocked by Cubit and UI guards.
- A06 includes existing password visibility, appearance and language controls even though the reference omits some of them. Real form values replace fictional design content.
- A08's verified action uses the existing return-to-sign-in path; it never assumes verification succeeded. A successful resend starts a real local 60-second cooldown; server throttling/errors remain authoritative.
- Initial profile bootstrap does not accept a photo. A09's optional photo control is omitted; existing profile photo management outside initial setup remains unchanged.
- Workspace creation only supports name/timezone. A11's job-title field is omitted rather than silently discarding it.
- Invitation details have no inviter name in the existing model. A13 omits fictional inviter/company text and displays available workspace, role, job title, email and dates.
- No token-preview API exists. A14 explicitly says **Accept invitation**, which performs the existing direct acceptance. No fake “Check invitation” step.
- A12 supports every actual invitation by opening its row; its View invitation action opens the first available invitation.
- A18's “Service information” has no existing supported destination and is omitted. Existing Retry and Sign out remain available.
- Responsive page widths, scrolling, keyboard insets and SafeArea replace fixed screenshot coordinates. OS status bars/home indicators are not painted into Flutter. Dark/Arabic screens other than sign-in, desktop/tablet layouts, loading/errors/empty states and switching sheet are derived from the extracted design system, not additional approved frames.
- This is a UI sprint; no backend contracts or identity/signing/application IDs are changed.

## Verification and review

Only the requested final `dart format .`, `flutter analyze`, and `flutter test` commands are to be run, once each. No baseline/focused Flutter tests, APK build, or git diff --check.

The capture test writes actual Flutter renders to ignored `.artifacts/access-workspaces/` for all implemented screen families at 390px English/light, 320px Arabic/1.6 text, and 1280px English/dark. It also exercises a keyboard-open sign-in form with a recoverable failure. Capture output and final command outcomes are recorded in the handoff; screenshots alone do not establish pixel parity.

## Manual regression

1. Launch signed out, restore an active session, expire it, and retry offline/service failures; confirm safe messages/request IDs and role routing.
2. Sign in with invalid and valid credentials. Toggle password visibility, change language/appearance, retry a failure and check input retention.
3. Register with invalid email, short/mismatched passwords and a valid account. Verify email, resend once, check cooldown/error, then return to sign in.
4. Submit blank/long profile names and optional phone, then save. Confirm entered values survive a recoverable failure.
5. Choose each workspace and verify its role home. Switch between employee and manager memberships and test suspended/removed memberships.
6. Create a workspace; check validation, timezone rejection, retry with retained values, duplicate protection, and back/closing transition.
7. Open My invitations, inspect details, accept and decline separately; test expired/removed invitations and offline retries.
8. Enter an invalid token, reveal/hide it, then accept a valid one and confirm real membership refresh.
9. Check 320px, 390px, tablet and desktop with keyboard open, long names, Arabic RTL and large accessibility text in light/dark/system modes.

## Actual final verification outcome

Each requested command was invoked exactly once, in order, on 2026-11-01. Commands were not repeated.

| Command | Actual result |
| --- | --- |
| dart format . | Exit 0. 710 files processed; 7 changed by this invocation. |
| flutter analyze | Exit 1. Two errors and three informational lints: overlapping constant translation-map keys; invalid TextFormField.obscureText assertion; child-argument ordering in two screens; missing braces in a test fixture. |
| flutter test | Exit 1. 732 passed, 26 failed; the screenshot test additionally did not complete. Its sole remaining worker stalled after the first PNG and was stopped after the other tests finished. |

The failure set included a runtime assertion in the merged Arabic constant map affecting multiple Arabic screens, old tests tapping controls outside a short viewport, and the previous inline decline-invitation path. This was not a successful final test run.

Corrections made after failed checks, **not reverified**:
- Removed the Access translation spread from the global constant map; AppLocalizations now resolves the focused Access dictionary separately.
- Fixed the token test to inspect EditableText, moved child arguments, and added fixture braces.
- Applied explicit semantic text/button/progress colors after the first screenshot exposed inherited white heading text and a teal progress color.
- Adjusted the restoring-session composition toward the reference's upper-center placement.
- Moved the complete image readback/write operation into tester.runAsync with bounded image-readback timeouts.
- Updated existing sign-in/registration and route-lifecycle tests to scroll and settle before tapping, and updated the decline-navigation test without removing its behavioral assertions.

No format, analyzer, or test command was repeated after these corrections. The current source is therefore **unverified after correction**, and must not be described as production-ready or pixel-matched.

### Visual comparison actually performed

Penpot PNG references were visually inspected for A02, A06 light/dark/Arabic, and A07–A18. Only **A02-restoring-reference.png** was actually captured from Flutter and inspected. It is at `.artifacts/access-workspaces/A02-restoring-reference.png` and depicts the state **before the last text/progress-color and vertical-placement fixes**. The approved app logo override was confirmed. No current screenshots exist for the other screens, and no parity claim is made.

### Files and assets changed

- Access screens/widgets/design tokens: `lib/features/auth/presentation/`.
- Integration: `lib/core/routing/app_router.dart`, `lib/core/localization/app_localizations.dart`, and formatting in `arabic_translations.dart`.
- Asset registration: `pubspec.yaml`; no dependency added.
- Exported vectors: `assets/access/icons/{back,file,user,work,plus,clock}.svg`.
- Bundled fonts/notices: `assets/access/fonts/{InterTight-Variable.ttf,NotoSansArabic-Variable.ttf,InterTight-OFL.txt,NotoSansArabic-OFL.txt}`.
- Tests: new Access design/capture tests and support fixtures; updated login, registration, profile, session-routing and onboarding assertions.
- Formatting-only differences remain in `lib/features/chat/data/cache/chat_group_cache.dart`, `lib/features/chat/presentation/widgets/chat_document_message.dart`, and `test/missed_attendance_review_test.dart`; no chat/attendance behavior was intentionally changed.
- Approved logo SHA-256 remains `CF9F759AC0187595F2B45C010C7D588A7B54D23D3C2C896215C9C004AA0DF022`.
- HEAD remains `6afc56aef4adde4b7952460e91023d1279837f70`. Changes are local and uncommitted.
