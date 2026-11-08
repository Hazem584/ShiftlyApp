String workDuration(int minutes, {bool arabic = false}) {
  final safe = minutes.clamp(0, 9999999);
  final hours = safe ~/ 60, remainder = safe % 60;
  if (arabic) {
    return remainder == 0
        ? '$hours ساعة'
        : hours == 0
        ? '$remainder دقيقة'
        : '$hours ساعة و$remainder دقيقة';
  }
  return remainder == 0
      ? '$hours h'
      : hours == 0
      ? '$remainder min'
      : '$hours h $remainder min';
}

String workDurationWithOvertime(
  int minutes,
  int overtime, {
  bool arabic = false,
}) {
  final work = workDuration(minutes, arabic: arabic);
  return overtime <= 0
      ? work
      : '$work · ${workDuration(overtime, arabic: arabic)} ${arabic ? 'وقت إضافي' : 'overtime'}';
}
