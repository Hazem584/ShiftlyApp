# Manager attendance reports

Open **Attendance & Leave → Attendance reports**. Managers can choose the current
week (Saturday–Friday), current month, previous/next periods, or a custom inclusive
date range of up to 366 days. The employee filter applies to every on-screen total,
table, and exported file. Employees with no matching records remain in the roster
with zero totals; this is not an absence determination.

The feature uses the existing manager-protected attendance and employee APIs.
No new backend endpoint, migration, Firebase setup, or scheduler is needed.
Every page is loaded before displaying/exporting the report, with a 10,000-record
and 10,000-roster-entry limit. A failed page, unexpected scope, duplicate record,
or changing pagination total fails the entire report instead of publishing partial
totals. These APIs use offset pagination, so this is not a database transaction
snapshot: concurrent edits that do not change the total can still appear. Refresh
before decisions; exports include their generation timestamp.

## Calculation rules

- Date filtering uses `clockInAt` in the active workspace's IANA timezone.
  Inclusive local calendar dates become UTC bounds independently, so daylight
  saving changes do not assume fixed 24-hour days. Overnight records are counted
  fully on their clock-in date rather than split between periods.
- Attendance days are distinct approved clock-in dates **per employee**. The
  overall sum is employee-days. Multiple shifts on one date count as one day.
- Late occurrences and late minutes use the server's stored `minutesLate`, only
  for approved records. Pending, rejected, unknown, and approved open records
  have their own counters. No clock-based late calculation replaces server rules.
- Worked hours sum the stored `workedMinutes` of approved, closed records only.
  Missing duration is counted separately rather than inferred. Breaks are not
  deducted because the existing canonical work duration is elapsed clock time.
- Extra shift hours are the approved closed hours of `occurrenceKind == EXTRA`.
  They are a subset of worked hours, not an additional amount to add to the total.
- Schedule excess is `max(0, workedMinutes - scheduledDuration)` for regular
  shifts. Template records use saved scheduled start/end evidence; legacy records
  use their shift start/end fallback. Missing or invalid schedule duration is
  counted separately. This estimate does not approve payroll or overtime pay.
- All current and inactive employees returned by the roster API are included;
  historical attendance whose employee is absent from that roster remains visible.

## Files and account boundaries

Excel exports are actual `.xlsx` files with Summary and Details worksheets.
Hours are numeric; names and other user content are explicitly text cells.
PDF exports contain the same filtered summary and detailed records, with the
bundled Cairo font and Arabic layout when the app language is Arabic.

On Android/iOS exports open the system share sheet (including available file-save
destinations). On Windows/macOS/Linux they open a save dialog. Web uses the share
plugin's browser share/download fallback. Users select the destination; no broad
storage permissions are requested.

Changing workspace, account, role, or signing out clears report data and cancels
obsolete results. An export being generated cannot be delivered after its report
scope is invalidated. Files already deliberately shared/saved remain with their
destination. Attendance review and related local mutations invalidate a loaded
report; pull to refresh also reloads it.

## Validation

Tests cover review-status accounting, multiple and overnight shifts, extra hours,
missing durations, timezone/DST period bounds, complete pagination, failed pages,
changed totals, stale session responses, matching employee filters, Excel decoding,
PDF creation with the bundled Arabic font, and the report screen. Native save/share
destinations must also be exercised on the intended devices.
