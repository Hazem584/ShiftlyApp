# Team work features

The manager Overview links to **Manager tasks** and **Team announcements**. Employees can open **Team announcements** and **Attendance corrections** from their Overview. Both roles use `/team-work`; data belongs to the active workspace and membership.

## Manager tasks

Pending correction, leave, and completed attendance reviews appear before follow-up items. Attendance and leave can be approved or declined from the card; declining requires a reason. A correction opens its original/requested times before a decision.

Follow-up includes today's late clock-ins, attendance past its scheduled end without clock-out, and missed starts for legacy shifts and assigned fixed shifts. Fixed shifts use the saved assignment schedule, workspace dates, overnight occurrences, and approved leave. Each category returns up to 50 items; the screen indicates when there are more items or schedules need review. Pull down to refresh.

## Attendance corrections

Completed fixed shifts without recorded attendance also support employee review requests and manager-selected approved hours. See [Missing attendance reviews](missed-attendance-reviews.md) for the API changes and required migration.

Employees use the edit-calendar action on a completed, non-rejected attendance record. They select the proposed start/end in the workspace timezone and give a reason. Requested times must form a completed period of up to 24 hours, ending before now. Submitting does not change attendance.

Only one request can be pending for each attendance record. A manager's approval atomically updates canonical times, late/worked minutes and classification, then synchronizes attendance points. Overlapping attendance and records changed since submission are blocked. Declining leaves attendance unchanged. Every request keeps the original/requested times, reason, reviewer, decision, review note and review time. The history can be filtered by status.

Correction notifications go to active managers and the requesting employee. The feature does not queue attendance corrections offline.

## Chat

The message menu offers **Reply**. The composer shows the selected message; cancel removes that selection. The reply target is saved with the outgoing text so offline retry preserves the reply. Canonical replies include a sender/text preview, even if the original message is outside the loaded page. Deleted originals do not expose their old text.

The conversation toolbar offers server-side search and a pinned-message list. Search includes older messages, is restricted to group members, and supports pagination. Managers who belong to a group can pin/unpin messages. Archived groups remain searchable; sending and pin changes are blocked.

## Announcements

Managers publish a title and message, optionally requiring acknowledgment. Active memberships are snapshotted at publication. A stable publication ID prevents duplicate notifications when the same submission is retried.

Opening the full announcement records reading. **I have read and understood** is a separate action after reading. The manager can inspect read/acknowledgment counts and each recipient's status. Publishing counts the author's own announcement as read/acknowledged. New members do not retroactively become recipients of older announcements.

Announcements and corrections use the existing notification/push pipeline; no additional Firebase secret or cron job is needed.

## Deployment order

The backend changes are in `E:\MY APPS\shiftly-backend`. Do not deploy this frontend against the previous backend.

1. Check the database destination and pending migrations:

   ```powershell
   Set-Location 'E:\MY APPS\shiftly-backend'
   npx prisma migrate status
   ```

2. Apply the reviewed migrations and regenerate Prisma:

   ```powershell
   npx prisma migrate deploy
   npx prisma generate
   ```

   `migrate deploy` applies **all pending migrations**, including `20261011190000_add_team_work`. This adds correction history, announcements/receipts and chat pin fields. New tables use the repository's existing API-only access pattern with RLS; the Flutter client accesses them through authenticated backend endpoints.

3. Deploy the backend, then deploy the web frontend/rebuild the mobile app. The local implementation does not apply the migration or deploy automatically.

## Acceptance checks

- Use two accounts in one workspace. Submit a completed attendance correction; verify that the record stays unchanged until approval, and that attendance, reports and points show the approved result after refresh.
- Try reviewing the same request from two managers, submit a second pending request, request overlapping times, and change attendance between submission/review. Verify one successful decision with a clear failure for conflicting changes.
- Reply to an older chat message, go offline before sending, reconnect and check the reply preview. Search older history, pin/unpin as a manager, and check that employees cannot change pins or search another group's messages.
- Publish an announcement requiring acknowledgment. Verify that listing its preview does not count as reading, opening it counts as read, and confirmation is separate. Inspect recipient counts with the manager account.
- Switch workspaces and accounts, test Arabic/English, small mobile widths and dark mode. Confirm no old workspace data appears after switching.

## API

### Announcements on the home screen

Pending announcements appear above the home screen content for employees and managers who received them. Each card shows the author, workspace-local publication time, and full announcement text. Rendering a card does not mark it as read. **I have read this** saves reading and hides a normal announcement; **Confirm I have read this** also saves acknowledgment for announcements requiring confirmation. A failed request keeps the card visible so the user can retry. The announcement remains available in the announcements archive.

The home screen requests `GET /team-work/announcements?pendingOnly=true`. The server filters the current membership's pending receipts before pagination, including previously read announcements awaiting acknowledgment. It uses the same filter for the total count. Refreshing the dashboard or returning the app to the foreground reloads the cards. Deploy the backend update before the app/web update; this change needs no additional migration.

- Verify both ordinary and acknowledgment-required announcements with two accounts.
- Verify a card stays visible after a failed read request and disappears after a successful retry, including after reopening the home screen.
- Verify changing workspaces shows only that membership's pending announcements, and archived/read items cannot hide older pending ones through pagination.

All paths below are relative to `/api/v1/workspaces/:workspaceId` and require an active authorized membership.

| Method | Path | Access |
|---|---|---|
| GET | `/team-work/tasks` | Manager |
| GET | `/team-work/corrections` | Manager: workspace; employee: own requests |
| GET | `/team-work/corrections/:id` | Manager: workspace; employee: own request |
| POST | `/team-work/corrections` | Employee |
| POST | `/team-work/corrections/:id/review` | Manager |
| GET | `/team-work/announcements` | Manager: workspace; employee: recipient |
| POST | `/team-work/announcements` | Manager |
| POST | `/team-work/announcements/:id/read` | Recipient |
| POST | `/team-work/announcements/:id/acknowledge` | Recipient |
| GET | `/team-work/announcements/:id/receipts` | Manager |
| GET | `/chat/groups/:groupId/search` | Group member |
| PATCH | `/chat/groups/:groupId/messages/:id/pin` | Manager and group member |
