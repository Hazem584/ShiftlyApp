class ShiftTemplateInput {
  const ShiftTemplateInput({
    required this.name,
    required this.color,
    required this.startMinute,
    required this.endMinute,
    required this.graceMinutes,
    required this.allowedEarlyCheckInMinutes,
    required this.allowedLateCheckInMinutes,
    required this.minimumWorkMinutes,
    this.description,
  });

  final String name;
  final String? description;
  final String color;
  final int startMinute;
  final int endMinute;
  final int graceMinutes;
  final int allowedEarlyCheckInMinutes;
  final int allowedLateCheckInMinutes;
  final int minimumWorkMinutes;

  int get durationMinutes {
    final difference = endMinute - startMinute;
    return difference <= 0 ? difference + 1440 : difference;
  }

  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 100) {
      return 'Enter a template name up to 100 characters.';
    }
    if (description != null && description!.trim().length > 1000) {
      return 'Description cannot exceed 1000 characters.';
    }
    if (!RegExp(r'^(#[0-9a-fA-F]{6}|[a-z][a-z0-9-]{0,39})$').hasMatch(color)) {
      return 'Choose a valid template color.';
    }
    if (startMinute < 0 ||
        startMinute > 1439 ||
        endMinute < 0 ||
        endMinute > 1439) {
      return 'Start and end times must be within one day.';
    }
    if ([
      graceMinutes,
      allowedEarlyCheckInMinutes,
      allowedLateCheckInMinutes,
      minimumWorkMinutes,
    ].any((value) => value < 0 || value > 1440)) {
      return 'Policy minutes must be between 0 and 1440.';
    }
    if (minimumWorkMinutes > durationMinutes) {
      return 'Minimum work time cannot exceed shift duration.';
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    if (description != null) 'description': description!.trim(),
    'color': color,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'graceMinutes': graceMinutes,
    'allowedEarlyCheckInMinutes': allowedEarlyCheckInMinutes,
    'allowedLateCheckInMinutes': allowedLateCheckInMinutes,
    'minimumWorkMinutes': minimumWorkMinutes,
  };
}
