part of '../../shift_editor_dialog.dart';

class ShiftEditorValue {
  const ShiftEditorValue({
    required this.employeeMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.notes,
  });

  final String employeeMembershipId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String notes;
}
