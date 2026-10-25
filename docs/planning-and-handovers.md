# Weekly planning and shift handovers

Open **Team work center / Team updates → Shift planning and handovers** using the assignment icon in the app bar. Managers see Weekly planning, Availability and skills, and Shift handovers. Employees see their handovers.

Managers first enter verified skill codes and dated availability windows. For five staff including a leader, add one requirement for one `leader` and a simultaneous general requirement for four employees. Proposals show explanations and rejection reasons. Review the choices and approve explicitly; proposals never publish automatically. A shortage needs an acknowledgement and a reason. If availability, leave or schedules change, generate a new proposal before approval.

Default policy: at most eight actual hours daily and 48 in a rolling seven-day window, a break of at least one hour for shifts longer than five hours, at most ten presence hours per shift, 24 weekly rest hours after at most six work days, and an operational rest policy of 12 hours between shifts. Individual weekly caps can be lowered and between-shift rest increased. The app does not implement special-sector/overtime exemptions. Existing fixed shifts without break records are counted conservatively as full work time. Arrange relief cover during breaks separately.

The planner includes individual shifts, effective fixed shifts and exceptions, approved leave, authorized extra shifts and attendance. Open attendance blocks additional assignments until reviewed. It is a deterministic greedy suggestion system; it does not guarantee the globally optimal roster. It handles one workspace at a time and adds individual shifts without replacing existing fixed-shift assignments.

Create a handover from a current/recent sending shift to a following receiving shift. Each operational item has a title, details, deadline and priority. Responsibility remains with the sender until the receiving employee confirms receipt. Updates require a progress note. Unresolved items can be carried to a following shift without losing their deadline or earlier history; resolved items remain in the earlier handover. Recipients can read the history carried into their handover but cannot edit earlier handovers.

Urgent or manually escalated items notify managers. Overdue items are highlighted and counted on the manager handover list, refreshed every 30 seconds. Automatic delayed push alerts on deadline expiry are not included. This workflow is separate from personal tasks.

Before deployment, apply backend migration `20261025220000_planning_handovers`, regenerate Prisma and deploy the backend. Then release a new Flutter build. The full backend implementation and policy reference are documented in the backend repository at `docs/planning-and-handovers.md`.
