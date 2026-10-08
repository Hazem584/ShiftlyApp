# Consistent 12-hour clock presentation

Reviewed Flutter HEAD `b284cf752346f348a81d51d38d2e560134d338db`, one worktree on Master, initially clean. No applicable AGENTS.md was found. No backend edits, commits, pushes, deployments, builds or Git history changes were made.

`ClockTime` centralizes wall-clock formatting with explicit `h:mm a`, locale-specific day periods, and uppercase English AM/PM (including English-GB). Existing `intl` is now a direct dependency at the already resolved/overridden 0.20.3 version; no new package version is introduced. Bundled date symbols initialize locally without network requests. Presentation callers pass the Flutter locale. The app's existing locale/delegate configuration remains unchanged and currently declares no additional UI locales; the formatter is also tested with Arabic labels.

`WorkspaceTime.time` and `dateTime` retain their existing IANA conversion, timezone suffix, null label and date format, delegating only the clock portion. Coverage includes dashboard, eligibility, fixed schedules, attendance, calendar details, leave requests, notifications, chat, manager/employee performance and point history. Fixed-shift minute values, editor wall times and employee shift summaries also use the shared formatter. Chat list previews now use the same workspace timezone as conversation timestamps instead of device-local conversion.

`ClockTimePicker` centralizes all three time-picker entry points (shift editor, template editor and leave request form), setting `alwaysUse24HourFormat: false` inside the dialog. Device 24-hour preference does not alter selection in the app's current English UI. The picker still returns the original `TimeOfDay` hour/minute. This change does not add support for new application locales or change date pickers.

UTC/ISO API payloads, stored minutes, workspace timezone conversion, date boundaries, overnight handling and duration calculations are unchanged. Elapsed recording timers, duration labels and voice playback positions remain duration displays. Utilities remain stateless presentation helpers; existing GetIt/feature ownership is unchanged. Each new utility has its own file/type.

## Actual verification

Each command was run exactly once:

| Command | Result |
| --- | --- |
| `dart format .` | Exit 0; 620 files processed, 18 changed; 5.18 seconds |
| `flutter analyze` | Exit 1; one existing `curly_braces_in_flow_control_structures` info in `chat_message_cache.dart`; 10.8 seconds |
| `flutter test` | Exit 1; 401 passed, 3 failed; approximately 71 seconds |

The analysis brace lint was corrected before the test run. Formatting and analysis were not repeated.

The three failing tests were:

- `clock_time_test`: midnight/noon/afternoon/English-GB — midnight, noon and 15:30 assertions passed, but `intl` supplied English-GB `8:00 am` instead of the required uppercase `8:00 AM`. The shared formatter now explicitly uppercases English day periods. **This post-test correction has not been formatted, analyzed or tested again.**
- Existing `chat_cache_outbox_test`: rapid text/location acceptance — the fake repository supplies the same canonical message ID for two text operations, producing two canonical rows instead of three. This unrelated fixture was not changed.
- Existing `manager_performance_widget_test`: compact/scaled employee target — existing Manager Performance layout overflows. This unrelated layout was not changed.

The other five new clock tests passed: locale-appropriate Arabic labels/fallback, overnight ranges and unchanged minutes/dates, IANA/DST/UTC payload preservation, 12-hour picker under a 24-hour device preference returning 15:30 unchanged, and an overnight label in a 280 px layout at 2x text scale. Existing timezone round-trip/DST tests also passed. The final tree is not claimed to have clean analysis or a passing test suite.

Full outputs are retained in ignored `.clock-format.log`, `.clock-analyze.log` and `.clock-test.log`. Repository-wide formatting also touched existing chat-cache/outbox formatting; the only semantic chat-cache change is the behavior-preserving brace fix.

## Manual spot checks

Use a workspace with an overnight shift and verify `11:00 PM – 6:00 AM`, including the next-day date. Check dashboard, attendance/calendar, leave and notification timestamps against the same workspace clock. Verify chat list/conversation timestamps match that workspace. Enable the device's 24-hour setting and open each of the three pickers: confirm AM/PM selection and unchanged submitted UTC/minute values. Inspect compact layouts and large text. Verify voice positions and recording elapsed timers still show durations.

## Changed files

The complete inventory below includes presentation locale forwarding, shared utilities, tests, direct dependency declaration, the brace fix and formatter-only changes.

- `docs/clock_time_handoff.md`
- `lib/core/models/shift.dart`
- `lib/core/utils/clock_time.dart`
- `lib/core/utils/clock_time_picker.dart`
- `lib/core/utils/workspace_time.dart`
- `lib/features/attendance/presentation/widgets/leave_request_card.dart`
- `lib/features/attendance/presentation/widgets/leave_request_details_dialog.dart`
- `lib/features/attendance/presentation/widgets/leave_request_form_dialog.dart`
- `lib/features/attendance/presentation/widgets/manager_attendance_panel.dart`
- `lib/features/attendance/presentation/widgets/parts/attendance_calendar_selected_day/private_employee_day_row.dart`
- `lib/features/attendance/presentation/widgets/parts/attendance_records_list/private_attendance_record_card.dart`
- `lib/features/attendance/presentation/widgets/parts/employee_leave_requests_panel/private_employee_leave_card.dart`
- `lib/features/attendance/presentation/widgets/parts/leave_request_form_dialog/private_leave_request_form_dialog_state.dart`
- `lib/features/attendance/presentation/widgets/parts/leave_request_form_dialog/private_time_button.dart`
- `lib/features/chat/data/cache/chat_message_cache.dart`
- `lib/features/chat/presentation/cubit/parts/chat_conversation_cubit/chat_outbox_pipeline.dart`
- `lib/features/chat/presentation/screens/chat_groups_screen.dart`
- `lib/features/chat/presentation/screens/parts/chat_groups_screen/private_group_tile.dart`
- `lib/features/chat/presentation/screens/parts/chat_screen/private_message_bubble.dart`
- `lib/features/dashboard/presentation/screens/parts/employee_dashboard_screen/private_employee_dashboard.dart`
- `lib/features/dashboard/presentation/screens/parts/employee_dashboard_screen/private_shift_card.dart`
- `lib/features/dashboard/presentation/widgets/parts/dashboard_activity_section/private_shift_tile.dart`
- `lib/features/employees/presentation/widgets/work_information_section.dart`
- `lib/features/fixed_shifts/presentation/widgets/employee_fixed_shifts_screen.dart`
- `lib/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/flexible_attendance_panel/private_active_attendance_card.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/flexible_attendance_panel/private_eligibility_tile.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/shift_templates_screen/private_template_card.dart`
- `lib/features/fixed_shifts/presentation/widgets/parts/shift_templates_screen/private_template_editor_dialog_state.dart`
- `lib/features/fixed_shifts/presentation/widgets/shift_templates_screen.dart`
- `lib/features/manager_performance/presentation/widgets/manager_audit_dialog.dart`
- `lib/features/manager_performance/presentation/widgets/manager_calendar.dart`
- `lib/features/manager_performance/presentation/widgets/manager_resource_list.dart`
- `lib/features/notifications/presentation/screens/parts/notifications_screen/private_notification_card.dart`
- `lib/features/points/presentation/widgets/points_calendar.dart`
- `lib/features/points/presentation/widgets/points_history.dart`
- `lib/features/shifts/presentation/screens/employee_shifts_screen.dart`
- `lib/features/shifts/presentation/widgets/parts/shift_card/shift_card.dart`
- `lib/features/shifts/presentation/widgets/parts/shift_editor_dialog/private_date_time_field.dart`
- `lib/features/shifts/presentation/widgets/parts/shift_editor_dialog/private_shift_editor_dialog_state.dart`
- `lib/features/shifts/presentation/widgets/shift_editor_dialog.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/clock_time_test.dart`
