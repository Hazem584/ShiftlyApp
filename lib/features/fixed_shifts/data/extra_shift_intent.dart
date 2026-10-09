import 'dart:convert';

import 'package:shiftly/core/network/api_model_parser.dart';

class ExtraShiftIntent {
  ExtraShiftIntent({
    required this.membershipId,
    required this.actual,
    required Map<String, Object?> payload,
  }) : payload = Map.unmodifiable(payload);
  final String membershipId;
  final bool actual;
  final Map<String, Object?> payload;
  String encode() => jsonEncode({
    'membershipId': membershipId,
    'actual': actual,
    'payload': payload,
  });
  factory ExtraShiftIntent.decode(String raw) {
    final json = ApiModelParser.map(jsonDecode(raw));
    if (json['actual'] is! bool)
      { throw const FormatException('Invalid saved operation'); }
    final payload = ApiModelParser.map(json['payload']);
    final allowed = {
      'shiftTemplateId',
      'operationalDate',
      'reason',
      'explanation',
      'clientAuthorizationId',
      if (json['actual'] == true) 'actualClockInAt',
      if (json['actual'] == true) 'actualClockOutAt',
    };
    if (payload.keys.any((key) => !allowed.contains(key)))
      { throw const FormatException('Unsupported saved request fields'); }
    for (final key in [
      'shiftTemplateId',
      'operationalDate',
      'reason',
      'explanation',
      'clientAuthorizationId',
    ]) {
      ApiModelParser.string(payload, key);
    }
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(payload['clientAuthorizationId'] as String))
      { throw const FormatException('Invalid saved request key'); }
    if (json['actual'] == true) {
      ApiModelParser.date(payload, 'actualClockInAt');
      ApiModelParser.date(payload, 'actualClockOutAt');
    }
    return ExtraShiftIntent(
      membershipId: ApiModelParser.string(json, 'membershipId'),
      actual: json['actual'] == true,
      payload: payload,
    );
  }
}
