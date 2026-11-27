import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

(int firstDay, int lastDay) scheduleWeekBounds(DateTime month, int week) {
  final maxDay = DateTime(month.year, month.month + 1, 0).day;
  final firstDay = (week * 7 + 1).clamp(1, maxDay);
  return (firstDay, (firstDay + 6).clamp(1, maxDay));
}

(List<EligibleShiftOccurrence>, List<ShiftRecord>) selectEmployeeScheduleWeek({
  required DateTime month,
  required int firstDay,
  required int lastDay,
  required String timezone,
  required List<EligibleShiftOccurrence> entries,
  required List<ShiftRecord> shifts,
}) {
  bool visible(String date) {
    final day = DateTime.parse(date);
    return day.year == month.year &&
        day.month == month.month &&
        day.day >= firstDay &&
        day.day <= lastDay;
  }

  final orderedShifts = [...shifts]
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return (
    entries.where((entry) => visible(entry.operationalDate)).toList(),
    orderedShifts
        .where(
          (shift) => visible(WorkspaceTime.dateKey(shift.startsAt, timezone)),
        )
        .toList(),
  );
}
