class CreateShiftInput {
  const CreateShiftInput({
    required this.employeeMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    this.notes,
  });
  final String employeeMembershipId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String? notes;

  Map<String, Object?> toJson() => {
    'employeeMembershipId': employeeMembershipId,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'breakMinutes': breakMinutes,
    'graceMinutes': graceMinutes,
    if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
  };
}
