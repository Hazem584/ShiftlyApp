import 'package:shiftly/core/monitoring/diagnostic_redaction.dart';

Map<String, Object> telemetryErrorPayload(
  String kind,
  String message,
  StackTrace stack,
  String? requestId,
) => {
  'kind': kind,
  'message': redactDiagnostic(message, 2000),
  'stack': redactDiagnostic(stack.toString(), 8000),
  if (requestId != null &&
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(requestId))
    'requestId': requestId,
};
