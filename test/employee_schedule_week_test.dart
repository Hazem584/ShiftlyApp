import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/employee_experience/domain/select_employee_schedule_week.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_employee_summary.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_record.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_status.dart';

void main() {
  test('last week ends on the last calendar day', () {
    expect(scheduleWeekBounds(DateTime(2028, 2), 4), (29, 29));
  });

  test('week includes shifts by workspace date and orders by start time', () {
    final (_, shifts) = selectEmployeeScheduleWeek(
      month: DateTime(2026, 2),
      firstDay: 1,
      lastDay: 7,
      timezone: 'Africa/Cairo',
      entries: const [],
      shifts: [
        _shift('second', DateTime.utc(2026, 2, 2, 10)),
        _shift('outside', DateTime.utc(2026, 2, 7, 23)),
        _shift('first', DateTime.utc(2026, 1, 31, 23)),
      ],
    );

    expect(shifts.map((shift) => shift.id), ['first', 'second']);
  });
}

ShiftRecord _shift(String id, DateTime startsAt) => ShiftRecord(
  id: id,
  workspaceId: 'workspace',
  employeeMembershipId: 'member',
  createdByMembershipId: 'manager',
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(hours: 1)),
  breakMinutes: 0,
  graceMinutes: 0,
  status: ShiftStatus.scheduled,
  createdAt: startsAt,
  updatedAt: startsAt,
  employee: const ShiftEmployeeSummary(
    membershipId: 'member',
    profileId: 'profile',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
  ),
);
