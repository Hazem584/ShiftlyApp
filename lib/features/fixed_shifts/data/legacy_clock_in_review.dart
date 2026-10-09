import 'flexible_attendance.dart';

/// A retained historical record. It is never a replayable v3 intent.
class LegacyClockInReview {
  const LegacyClockInReview({
    required this.storageKey,
    required this.message,
    this.clientAttendanceId,
    this.canonical,
  });

  final String storageKey;
  final String message;
  final String? clientAttendanceId;
  final FlexibleAttendance? canonical;
  bool get requiresReview => canonical == null;
}
