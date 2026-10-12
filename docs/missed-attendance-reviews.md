# Missing attendance reviews

Completed fixed-shift occurrences with no recorded attendance show the shift name, operational date and a neutral “No attendance recorded” explanation. Future shifts show that check-in has not opened; elapsed lateness is shown only for a currently eligible, unused shift. A completed shift can have a review request; a closed check-in window alone does not establish absence.

The employee selects “I attended but forgot to record attendance”, “I have an exception or special circumstance”, or another reason, explains the request and chooses the period to count. The default is the entire saved shift. Times are interpreted in the saved schedule timezone, including overnight shifts; nonexistent DST times are rejected and repeated times require choosing an offset. Requests must stay inside the saved shift and cover at least one completed minute, up to 24 hours.

Submitting creates an audit request and notifies active managers. It creates no attendance and credits no hours. Refresh shows pending review and links to Attendance corrections. Only one request may be pending for an occurrence.

Managers review requests from Manager tasks or Attendance corrections. Approval opens a time editor: the manager may accept all or part of the requested period. Changing the employee's times requires a review note. Declining requires a reason and creates no attendance. Employees see both requested and approved periods, the decision, reviewer and note in history.

Approval creates canonical approved attendance only after checking ownership, active membership, assignment/authorization, saved schedule evidence, occurrence reuse and overlapping attendance. Extra authorizations are consumed only on approval. Creation, review, attendance and notification changes are transactional. Concurrent decisions cannot both succeed. Canonical attendance recalculates worked/late minutes and synchronizes the existing points rules. An exception is a reason for manager review, not an automatic override of the points policy.

## API changes

Relative to `/api/v1/workspaces/:workspaceId/team-work`:

- Employee `POST /corrections/missed`: exactly one of `assignmentId` or `extraAuthorizationId`, `operationalDate` (`YYYY-MM-DD`), `reasonKind` (`FORGOT_TO_RECORD`, `EXCEPTION`, `OTHER`), `clockInAt`, `clockOutAt` (UTC instants), and `reason` (5–1000 characters).
- Manager `POST /corrections/:id/review`: existing `decision` and optional `note`, plus optional `clockInAt` and `clockOutAt` supplied together. Omitting times preserves requested times. A note is mandatory for rejection or changed approved times.
- Correction responses include nullable original times/attendance ID for missing attendance, `occurrenceSnapshot`, `reasonKind`, and `approvedClockInAt`/`approvedClockOutAt`. Once approved, `attendanceId` identifies the newly created record.
- Eligibility occurrences include `pendingReview`, scoped to the current employee and exact occurrence.

The check-in endpoint is unchanged; these requests never reopen or backdate a clock-in.

## Deployment

Backend source is in `E:\MY APPS\shiftly-backend`. Apply the reviewed migration `20261012190000_missed_attendance_reviews`, regenerate Prisma, and deploy the backend before rebuilding/deploying Flutter. Source implementation does not apply database migrations or deploy automatically. `prisma migrate deploy` applies all pending migrations; review them and confirm the destination before running it.

Focused tests cover employee reasons and failed retries, Arabic mobile layouts, manager partial approval, UTC API payloads, Cairo DST gaps/folds, pending requests, scoped assignments, duplicate/overlapping attendance, changed schedules, rejected requests, extra authorization consumption and concurrent database conflicts. Database constraints have been reviewed in source; a disposable-database integration test and two-account acceptance check remain deployment checks.
