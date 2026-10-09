import 'package:shiftly/core/serialization/api_model_parser.dart';

/// An immutable server audit record; unknown fields are never presented as metrics.
class ManagerPointsRecord {
  ManagerPointsRecord(Map<String, Object?> json)
    : id = json['operationalDate'] is String && json['id'] == null
          ? json['operationalDate']! as String
          : ApiModelParser.string(json, 'id'),
      fields = Map.unmodifiable(json);

  final String id;
  final Map<String, Object?> fields;
  String text(String key) => fields[key]?.toString() ?? 'Unknown';
  bool get reversed => fields['reversedAt'] != null;
}
