# Phase 2 — Manager Experience

## Baseline

- Actual initial HEAD: `6cfe0109859620ed8f193946ca76149eb68410cf`.
- Initial worktree: clean (`git status --short` produced no changes).
- Phase 1 handoff: `docs/access-workspaces-design.md`. It records failed checks and subsequent unverified corrections; these have been preserved.
- No branch changes, commits, pushes, builds, deployment, backend/schema edits or production-data access.
- Penpot is read/export reference only. The design file is not modified by Phase 2.
- Approved app logo: `assets/images/shiftly-mark.png`, rendered through `lib/core/widgets/brand_logo.dart`. No logo was exported from Penpot or replaced.

## Progress — six batches implemented; repair verification passed

1. Manager theme/navigation/overview: implemented; see verification results below.
2. Team/directory/invitations/details: implemented; see verification results below.
3. Scheduling: list/details and two-step template form implemented; supported assignment/extra/exception forms connected.
4. Attendance/corrections/leave: compact record cards, confirmations and review lifecycle guards implemented.
5. Announcements/reports: manager home preview, searchable recipient progress and compact reports implemented; see verification results below.
6. Profile/settings: role-aware title, sign-out/cache confirmations, existing preference/device/avatar workflows retained; acceptance review remains.

The original constrained pass is recorded below. The user subsequently requested a full inspection and repair on 1 November 2026; that follow-up authorizes the additional verification recorded at the end.

## Frame mapping

These are actual connected-frame names and IDs. Mapping records the target, not a claim of pixel parity. Production data replaces fictional design values. Existing forms are retained where necessary for supported policy/recovery behavior.

| Approved frame | Frame ID | Flutter target |
| --- | --- | --- |
| B01 — Manager / Overview | `a1ffe3ad-97e8-8098-8008-e09e850fcc4c` | `lib/features/manager/presentation/widgets/manager_overview.dart` |
| B01-Dark — Manager / Overview / Dark | `3c6bc856-584c-8060-8008-e14ab9d202ba` | `lib/features/manager/presentation/widgets/manager_overview.dart` |
| B01-AR — Manager / Overview / العربية RTL | `3c6bc856-584c-8060-8008-e14a972b62ce` | `lib/features/manager/presentation/widgets/manager_overview.dart` |
| B03 — Team / Directory | `a1ffe3ad-97e8-8098-8008-e09e8890c9ea` | `lib/features/employees/presentation/screens/employees_screen.dart` |
| B03-Dark — Team / Directory / Dark | `3c6bc856-584c-8060-8008-e14abd33d4ce` | `lib/features/employees/presentation/screens/employees_screen.dart` |
| B03-AR — Team / Directory / العربية RTL | `3c6bc856-584c-8060-8008-e14a9e24448d` | `lib/features/employees/presentation/screens/employees_screen.dart` |
| B02 — Manager / Action inbox | `a1ffe3ad-97e8-8098-8008-e09f2982d233` | `lib/features/team_work/presentation/widgets/manager_tasks_view.dart` |
| B04 — Team / Invite employee | `a1ffe3ad-97e8-8098-8008-e09f2b398109` | `lib/features/employees/presentation/screens/add_employee_screen.dart` |
| B05 — Team / Invitation created | `a1ffe3ad-97e8-8098-8008-e09f2ca0b74e` | `lib/features/employees/presentation/screens/add_employee_screen.dart` |
| B06 — Team / Invitation history | `a1ffe3ad-97e8-8098-8008-e09f2dd17f05` | `lib/features/manager/presentation/screens/manager_invitation_history.dart` |
| B07 — Team / Omar Adel | `a1ffe3ad-97e8-8098-8008-e09f2f51e10e` | `lib/features/employees/presentation/widgets/employee_details_view.dart` |
| B08 — Deactivate Omar? | `a1ffe3ad-97e8-8098-8008-e09f30bfe30a` | `lib/features/employees/presentation/widgets/employee_details_view.dart` |
| C01 — Schedules / Shift templates | `a1ffe3ad-97e8-8098-8008-e09f31983193` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C02 — Schedules / Morning operations | `a1ffe3ad-97e8-8098-8008-e09f3355a59c` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C05 — Archive this template? | `a1ffe3ad-97e8-8098-8008-e09f3a42cac5` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C03 — Schedules / Create template | `a1ffe3ad-97e8-8098-8008-e09f35223535` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C03b — Schedules / Template policy | `a1ffe3ad-97e8-8098-8008-e09f36950f00` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C04 — Schedules / Edit template | `a1ffe3ad-97e8-8098-8008-e09f38bfe2db` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C06 — Assignment / Omar Adel | `a1ffe3ad-97e8-8098-8008-e09f3b17f85a` | `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart; assignment_form.dart` |
| C07 — Assignment / Version history | `a1ffe3ad-97e8-8098-8008-e09f3d522b29` | `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart; assignment_form.dart` |
| C08 — Assignment / New version | `a1ffe3ad-97e8-8098-8008-e09f3e720d17` | `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart; assignment_form.dart` |
| C09 — Extras / Authorization history | `a1ffe3ad-97e8-8098-8008-e09f40ba5e36` | `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart; extra_authorization_card.dart; extra_shift_form.dart` |
| C10 — Extras / Authorize shift | `a1ffe3ad-97e8-8098-8008-e09f428853c6` | `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart; extra_authorization_card.dart; extra_shift_form.dart` |
| C11 — Extras / Authorization details | `a1ffe3ad-97e8-8098-8008-e09f44fd4b6c` | `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart; extra_authorization_card.dart; extra_shift_form.dart` |
| C12 — Revoke extra shift? | `a1ffe3ad-97e8-8098-8008-e09f46bd8115` | `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart; extra_authorization_card.dart; extra_shift_form.dart` |
| C13 — Extras / Record completed work | `a1ffe3ad-97e8-8098-8008-e09f47bf5958` | `lib/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart; extra_authorization_card.dart; extra_shift_form.dart` |
| C14 — Exceptions / Date changes | `a1ffe3ad-97e8-8098-8008-e09f4a9ba9ca` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| C15 — Exceptions / Create exception | `a1ffe3ad-97e8-8098-8008-e09f4c3c6481` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| C16 — Exceptions / Change details | `a1ffe3ad-97e8-8098-8008-e09f4f36e3ce` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| C17 — Cancel this exception? | `a1ffe3ad-97e8-8098-8008-e09f50d65bd9` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| D01 — Attendance / Team records | `a1ffe3ad-97e8-8098-8008-e14746efa80f` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D02 — Attendance / Daily view | `a1ffe3ad-97e8-8098-8008-e14748a6b54f` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D03 — Attendance / Monthly calendar | `a1ffe3ad-97e8-8098-8008-e1474a110562` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D04 — Attendance / Omar Adel | `a1ffe3ad-97e8-8098-8008-e1474fceb6b7` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D06 — Reject attendance | `a1ffe3ad-97e8-8098-8008-e14751d94070` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D05 — Approve attendance? | `a1ffe3ad-97e8-8098-8008-e147514bb837` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| D07 — Corrections / Review requests | `a1ffe3ad-97e8-8098-8008-e147528f3805` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| D08 — Corrections / Compare times | `a1ffe3ad-97e8-8098-8008-e14753c92909` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| D10 — Decline correction | `a1ffe3ad-97e8-8098-8008-e14756c072bd` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| D09 — Corrections / Approve request | `a1ffe3ad-97e8-8098-8008-e14755645d3e` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| D09-AR — Corrections / Approve request / العربية RTL | `3c6bc856-584c-8060-8008-e14aa991d1e3` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| D11 — Corrections / Decision history | `a1ffe3ad-97e8-8098-8008-e147578a51b5` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| E01 — Leave / Team requests | `a1ffe3ad-97e8-8098-8008-e1475a09a5d1` | `lib/features/attendance/presentation/widgets/leave_request_card.dart; leave_request_details_dialog.dart` |
| E02 — Leave / Lina Nasser | `a1ffe3ad-97e8-8098-8008-e1475c350ca2` | `lib/features/attendance/presentation/widgets/leave_request_card.dart; leave_request_details_dialog.dart` |
| E04 — Decline leave | `a1ffe3ad-97e8-8098-8008-e1475ec98c24` | `lib/features/attendance/presentation/widgets/leave_request_card.dart; leave_request_details_dialog.dart` |
| E03 — Approve Lina’s leave? | `a1ffe3ad-97e8-8098-8008-e1475e09b044` | `lib/features/attendance/presentation/widgets/leave_request_card.dart; leave_request_details_dialog.dart` |
| K01 — Reports / Attendance summary | `a1ffe3ad-97e8-8098-8008-e148de03a4f7` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K02 — Reports / Reporting period | `a1ffe3ad-97e8-8098-8008-e148e09c3b6d` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K03 — Reports / Employee filter | `a1ffe3ad-97e8-8098-8008-e148e211be00` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K04 — Reports / Omar Adel | `a1ffe3ad-97e8-8098-8008-e148e3e65157` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K05 — Reports / Attendance record | `a1ffe3ad-97e8-8098-8008-e148e5b7de72` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K06 — Reports / Preparing export | `a1ffe3ad-97e8-8098-8008-e148e76f562a` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K06b — Reports / Export failed | `a1ffe3ad-97e8-8098-8008-e148e8acedd4` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| K07 — Reports / Export ready | `a1ffe3ad-97e8-8098-8008-e148e9cbf004` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| C04b — Schedules / Edit template identity | `3c6bc856-584c-8060-8008-e14bcb1131a7` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| C15b — Exceptions / Employee day off | `3c6bc856-584c-8060-8008-e14bcff0a200` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| C15c — Exceptions / Workspace closure | `3c6bc856-584c-8060-8008-e14bd3ff4745` | `lib/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart` |
| C08b — Assignment / Schedule conflict | `3c6bc856-584c-8060-8008-e14bd7693896` | `lib/features/fixed_shifts/presentation/widgets/work_pattern_view.dart; assignment_form.dart` |
| D01b — Attendance / Filter records | `3c6bc856-584c-8060-8008-e14bdb423028` | `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart; screens/attendance_screen.dart` |
| K06c — Reports / Export format | `3c6bc856-584c-8060-8008-e14be66a7b4c` | `lib/features/reports/presentation/attendance_reports_screen.dart; compact_attendance_report.dart` |
| NAV01 — Manager / Work hub | `3c6bc856-584c-8060-8008-e14c33ba84ce` | `lib/features/shell/presentation/screens/work_hub_screen.dart` |
| C01b — Schedules / Archived templates | `3c6bc856-584c-8060-8008-e14d4ddd82fd` | `lib/features/fixed_shifts/presentation/screens/shift_templates_screen.dart; widgets/shift_template_details.dart; dialogs/shift_template_editor_dialog.dart` |
| D08b — Corrections / Missing attendance | `3c6bc856-584c-8060-8008-e14f836de4f2` | `lib/features/team_work/presentation/widgets/correction_request_card.dart; dialogs/correction_approval_dialog.dart` |
| B07b — Team / Amir Khaled | `3c6bc856-584c-8060-8008-e150d5debc60` | `lib/features/employees/presentation/widgets/employee_details_view.dart` |
| B08b — Team / Activate employee confirmation | `3c6bc856-584c-8060-8008-e150dc396eb3` | `lib/features/employees/presentation/widgets/employee_details_view.dart` |
| I01 — Announcements / Pending updates | `a1ffe3ad-97e8-8098-8008-e148d6087ce5` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I02 — Announcements / Archive | `a1ffe3ad-97e8-8098-8008-e148d6acafd9` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I03 — Announcements / Safety briefing | `a1ffe3ad-97e8-8098-8008-e148d76e78ed` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I05 — Acknowledge this update? | `a1ffe3ad-97e8-8098-8008-e148d8dd69bb` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I04 — Announcements / Publish update | `a1ffe3ad-97e8-8098-8008-e148d82f3d87` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I06 — Announcements / Recipient progress | `a1ffe3ad-97e8-8098-8008-e148d92f9b29` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| I07 — Announcements / Omar Adel | `a1ffe3ad-97e8-8098-8008-e148da1562bc` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |
| J01 — Notifications / Inbox | `a1ffe3ad-97e8-8098-8008-e148dac91893` | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| J02 — Notifications / Read and unread | `a1ffe3ad-97e8-8098-8008-e148dba266aa` | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| J03 — Notifications / Stay informed | `a1ffe3ad-97e8-8098-8008-e148dca9993d` | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| J04 — Notifications / Item unavailable | `a1ffe3ad-97e8-8098-8008-e148dd312a13` | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| L01 — Profile / Omar Adel | `a1ffe3ad-97e8-8098-8008-e1492d76b88c` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L12 — Sign out of Shiftly? | `a1ffe3ad-97e8-8098-8008-e1493b0e3ee9` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L01b — Profile / Maya Hassan | `a1ffe3ad-97e8-8098-8008-e1492eec8e38` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L02 — Profile / Edit information | `a1ffe3ad-97e8-8098-8008-e1493049fef1` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L03 — Profile photo | `a1ffe3ad-97e8-8098-8008-e149314f5910` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L04 — Preferences / Language | `a1ffe3ad-97e8-8098-8008-e149324e19c6` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L05 — Preferences / Appearance | `a1ffe3ad-97e8-8098-8008-e149339d6b24` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L06 — Workspace / Switch workspace | `a1ffe3ad-97e8-8098-8008-e149352a95e6` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L07 — Security / Devices and sessions | `a1ffe3ad-97e8-8098-8008-e149364cc0fe` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L08 — Revoke this session? | `a1ffe3ad-97e8-8098-8008-e149374b3fb7` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L09 — Storage / Chat cache | `a1ffe3ad-97e8-8098-8008-e14937d5af64` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L10 — Clear cached media? | `a1ffe3ad-97e8-8098-8008-e14939402cef` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L11 — Support / Service information | `a1ffe3ad-97e8-8098-8008-e14939ceb3b0` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| L12b — Profile / Signing out | `a1ffe3ad-97e8-8098-8008-e1493ba98ca3` | `lib/features/profile/presentation/screens/profile_screen.dart; lib/features/device_sessions/presentation/` |
| I05b — Announcements / Acknowledged | `3c6bc856-584c-8060-8008-e14d581405c9` | `lib/features/team_work/presentation/widgets/announcements_view.dart; dialogs/announcement_readers_dialog.dart` |

## Components and assets

- Reuse Phase 1 AccessInter / AccessArabic fonts and existing OFL notices, AccessTheme and AccessTokens.
- ManagerTheme scopes semantic indigo/neutral colors, 16px body, 14px support, 52px actions, 12px field radii, 14px buttons, 16px surfaces and 20px overview card.
- AppPalette reads a ManagerThemeMarker; employee colors remain the original palette.
- Existing Material outlined icons remain suitable vector controls. No additional artwork/assets/dependency needed; no screen rasterization.
- New focused widgets include manager overview/attendance summary, record tiles, confirmation sheet, reason dialog, announcement preview, recipient progress and compact report cards.

## Contract differences and intentional adaptations

- Directory contract exposes membership status, not real-time shift status. Membership filters remain All/Active/Suspended; no invented On shift total/filter.
- Dashboard supplies real clocked-in/scheduled/late/leave totals and pending-leave count. No fabricated total for all outstanding decisions. Operational inbox supplies its own actual work feed.
- InvitationRepository supports create/list/accept/decline but no manager revoke mutation. History displays revoked status when returned; there is no fake revoke button. Token sharing is available on creation; expired/history tokens are not regenerated.
- Existing session coordinator, feature-scope guards, GetIt, Cubits, GoRouter, authenticated Dio and canonical repository contracts remain authoritative.
- Old notification and legacy URLs continue to resolve. Work hub is `/work`; review inbox remains `/work?tab=tasks`, distinct from personal `/tasks` and `/work?tab=personal`.
- Existing assignment versioning and durable extra-operation recovery are reused; no legacy per-employee shift creation or Points/Performance modules added.
- Home announcement previews create no read/acknowledgment receipts. Full content is opened deliberately; acknowledgment remains a distinct confirmed action.
- Report aggregation/export rules are unchanged. Compact cards preserve metrics; desktop tables scroll horizontally.
- Native safe areas, responsive scrolling and keyboard insets replace painted system bars and fixed screenshot positions.

## Manual manager-to-employee regression

1. Sign in as manager; switch workspace from Home and verify overview/directory/inbox immediately clear old membership data.
2. Search/filter/page the directory; invite/copy/share; inspect invitation status and cancel/reactivate confirmations.
3. Create/edit/archive a template; assign a dated weekday version; inspect prior versions and policy validation.
4. Authorize/revoke/record extra work, retry an unresolved operation and verify the same request ID and canonical linked attendance.
5. Review attendance, corrections and leave; verify reasons and server errors survive retry; inspect calendar and report periods/export.
6. Open an announcement then acknowledge separately; inspect searchable reader progress.
7. Change language/appearance/profile, inspect sessions/cache, enter chat and personal tasks and verify Back.
8. Switch into employee membership while manager requests are pending; confirm manager routes redirect, employee data only, shared chat/tasks still work; sign out.

## Known presentation adaptations

Existing calendar, corrections comparison, assignment, extra recovery, exception audit and notification content remain the supported production widgets under the manager theme. These are connected and restyled but have not been established as exact visual reproductions of every mapped frame. No new raster/vector assets or dependencies were added. Remaining acceptance work is any visual refinement identified by final captured renders and a device/manual regression; it must not be represented as verified parity.

## Original verification — 1 November 2026 (superseded by repair follow-up)

| Command (one invocation each, in order) | Recorded result |
| --- | --- |
| dart format . | Waited silently on the Flutter SDK cache lock. The session was interrupted and returned exit 1 without a completion summary. Formatting changes are present, including Phase 1 files; no clean formatter completion is claimed. |
| flutter analyze | Exit 1; 38 issues: 3 errors and 35 informational lints. Errors were EdgeInsets.zero incorrectly prefixed with const (2 diagnostics) and the retired WorkHubScreen.tabs test reference. Those were corrected afterward; analysis was not repeated. |
| flutter test | Exit 1 after 2:04; 752 passed, 13 failed. This is the only full test run. |

Failed tests: Arabic manager localization; two report export widget tests; two dashboard loading/refresh tests; template-card clearance; manager leave approval; manager render capture; attendance reference screen; employee deactivate/reactivate; manager task destinations; manager logout; Arabic web responsive layout.

### Corrections after original failed checks — initially unverified

- Removed invalid const before EdgeInsets.zero and updated supported-navigation assertions to the new destinations list (including reports).
- Increased bottom navigation height with text scaling and reduced vertical item margins to address the measured 0.2px / 2.9px overflows.
- Removed the outer horizontal scroll wrappers around PaginatedDataTable: the table already owns horizontal scrolling, and its header requires bounded width. Compact report cards remain below 700px.
- Updated tests to explicitly confirm manager leave approval, reactivation and sign-out; use the new summary key and scope attendance headings to AppBar.
- Updated archived-template clearance tests to use a stable per-template key instead of removed inline detail copy; preserved the final-card/FAB clearance assertion.
- Added owner checks to employee-status confirmation and template-detail actions; fixed two-column template spacing; preserved support request IDs in employee-picker failures.
- Capture harness now selects the real ThemeCubit mode and loads MaterialIcons. These changes have not produced replacement screenshots and must not be treated as visually verified.

During the original pass no baseline/focused test, rerun, APK build, git diff --check, commit, push, branch change or deployment was performed. Subsequent user-authorized repair verification is recorded separately below.

## Actual visual evidence and remaining acceptance work

Four Flutter captures were generated in .artifacts/manager-experience: B01-overview-reference.png, B03-directory-reference.png, NAV01-work-reference.png and K01-profile-reference.png (the last filename labels the profile incorrectly; its source frame is L01b). These are test-fixture renders, not invented production statistics.

B01 and B03 Flutter renders were visually inspected against exported Penpot B01 (a1ffe3ad-97e8-8098-8008-e09e850fcc4c) and B03 (a1ffe3ad-97e8-8098-8008-e09e8890c9ea). Structure, spacing, attendance surface and team-card hierarchy were compared. The captured app used its default dark mode rather than the requested light reference, and icons rendered as missing glyphs because the capture harness did not load MaterialIcons. Directory filters intentionally show actual membership status, while the design depicts attendance states unavailable in that contract. Overview omits fictional pending totals and absent announcement cards. Bottom-navigation selection styling is an adaptation, not pixel parity.

The NAV01 Flutter render was inspected, but its fresh Penpot export did not return a rendered image, so no fresh paired NAV01 visual comparison is claimed. Profile capture exists but was not visually compared. Compact RTL/large-text and desktop captures did not complete because the render test failed on navigation overflow. No full visual parity is claimed. Remaining acceptance work: revalidate the unverified fixes, obtain corrected light/dark/RTL/desktop captures, refine remaining form/detail frame differences, and perform the manual manager-to-employee sequence above. This original acceptance assessment is superseded by the later repair verification below; exact visual parity and manual device acceptance remain separate.

## Changes and retained boundaries

All frame names/IDs and target paths are listed above. Source changes span manager-scoped design, shell/routes, dashboard, team/invitations, template/details, attendance/review, announcements/receipts, compact reports and profile/settings. Targeted search/filter, canonical mutation/refresh, duplicate mutation and controller-lifecycle regressions were added. Existing assignment/extra/recovery/report/scope business tests remain. Final changed-file manifest is manager-experience-changed-files.txt.

No dependencies, backend/schema, Firebase/signing/app IDs, branding assets or Penpot design were changed. The original assets/images/shiftly-mark.png remains through BrandLogo. Existing GetIt/Bloc/GoRouter/authenticated Dio, session-scoped repositories, chat/conversation/personal-task routes and report export/delivery remain authoritative. Phase 1 formatter-only changes are retained; no prior work was reset. Final HEAD remains 6cfe0109859620ed8f193946ca76149eb68410cf.


## Latest repair verification — user-requested inspection and fixes

The user's subsequent request, “افحص وظبط كل حاجه”, authorized renewed inspection, fixes and verification. The original failure record above remains as history; the results in this section supersede its unverified status.

- Applied 47 Dart fixes across 31 files: import ordering, braces, string interpolation and null-aware elements. Lint rules were preserved; no suppression was added.
- Formatting completed successfully across 729 Dart files. A final format applied the last helper's brace layout; no behavioral edit followed the successful full test run.
- Final flutter analyze --no-pub: No issues found (31.5 seconds). Log: .artifacts/manager-analyze-final.log.
- Final flutter test --no-pub: 765 passed, zero failed (2:09). Log: .artifacts/manager-test-final.log. The preceding repair run exposed two remaining issues and finished 763 passed / 2 failed; both were fixed before this final successful run.
- Extracted attendance approval into lib/features/attendance/presentation/utils/approve_manager_attendance.dart. The panel now stays below the project's 500-line limit; approval keeps explicit confirmation and verifies cubit scope ownership before and after the request.
- Corrected attendance reference assertions to scope the actual ScreenHeader rather than an absent AppBar, while preserving the title and workflow assertions.
- At large text scales, manager bottom navigation scrolls horizontally with readable destination widths. The compact RTL render test exercises reaching Profile and returning Home. Default text scale retains all five destinations across the available width.
- Manager navigation rail now uses manager fonts rather than inheriting the legacy Cairo label style.
- The earlier failures in reports/export, dashboard refresh, template clearance, employee activation, leave review, navigation, sign-out and compact Arabic layouts are covered by the final passing full suite. Business assertions were retained.

### Render inspection in this repair

Generated 12 current Flutter captures under .artifacts/manager-experience: overview, directory, work hub and profile, each at 390px light, 320px Arabic RTL with text scale 1.6, and 1280px desktop dark. The old K01-profile-reference.png is historical; the current correct filename prefix is L01b-profile.

Visually inspected the new overview light, directory compact RTL and profile desktop dark renders. Light mode and MaterialIcons now load correctly. Large Arabic navigation words no longer split into unreadable fragments; horizontal navigation is intentional at enlarged text size. Desktop rail text now renders with the correct font. The existing B01/B03 Penpot comparison remains valid as a structural reference; no new exact-pixel parity claim is made for unreviewed frames. Manual device interaction and exact visual refinement of the retained detailed forms remain acceptance tasks, separate from the clean analysis and passing automated suite.

No commit, push, branch change, APK build, deployment, backend/schema modification or Penpot mutation was made. Logo/assets/dependencies remain unchanged. Final HEAD remains 6cfe0109859620ed8f193946ca76149eb68410cf.
