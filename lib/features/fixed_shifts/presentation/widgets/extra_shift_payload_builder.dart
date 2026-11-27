import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/utils/workspace_timestamp_input.dart';

Map<String, Object?> buildExtraShiftPayload({
  required String? templateId,
  required DateTime date,
  required String reason,
  required String explanationText,
  required bool actual,
  required String actualInText,
  required String actualOutText,
  required String timezone,
}) {
  final payload = <String, Object?>{
    'shiftTemplateId': templateId,
    'operationalDate': WorkspaceTime.localDateKey(
      year: date.year,
      month: date.month,
      day: date.day,
    ),
    'reason': reason,
    'explanation': explanationText,
  };
  if (actual) {
    final start = WorkspaceTimestampInput.parse(actualInText, timezone);
    final end = WorkspaceTimestampInput.parse(actualOutText, timezone);
    WorkspaceTimestampInput.validateRange(start, end, DateTime.now().toUtc());
    payload['actualClockInAt'] = start.toIso8601String();
    payload['actualClockOutAt'] = end.toIso8601String();
  }
  return payload;
}
