part of '../../shift_repository.dart';

class UpdateShiftInput {
  const UpdateShiftInput({
    this.employeeMembershipId,
    this.startsAt,
    this.endsAt,
    this.breakMinutes,
    this.graceMinutes,
    this.notes,
  });
  final String? employeeMembershipId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? breakMinutes;
  final int? graceMinutes;
  final String? notes;

  Map<String, Object?> toJson() => {
    if (employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (startsAt != null) 'startsAt': startsAt!.toUtc().toIso8601String(),
    if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
    if (breakMinutes != null) 'breakMinutes': breakMinutes,
    if (graceMinutes != null) 'graceMinutes': graceMinutes,
    if (notes != null) 'notes': notes!.trim(),
  };
}
