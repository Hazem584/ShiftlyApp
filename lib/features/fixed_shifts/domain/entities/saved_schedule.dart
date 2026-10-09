import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/utils/clock_time.dart';

/// Immutable evidence, independent of the editable template catalog.
class SavedSchedule {
  SavedSchedule(Map<String, Object?> fields)
    : fields = Map.unmodifiable(fields) {
    for (final key in ['id', 'name', 'timezone']) {
      ApiModelParser.string(fields, key);
    }
    for (final key in ['startMinute', 'endMinute']) {
      final minute = ApiModelParser.integer(fields, key);
      if (minute < 0 || minute > 1439) {
        throw const FormatException('Invalid saved schedule');
      }
    }
  }
  final Map<String, Object?> fields;
  String get name => fields['name'] as String;
  String get timezone => fields['timezone'] as String;
  String? get conversionPolicy =>
      ApiModelParser.optionalString(fields['conversionPolicy']);
  bool get supported =>
      conversionPolicy == 'POSTGRES_V1' ||
      conversionPolicy == null ||
      conversionPolicy == 'LEGACY_UNVERSIONED';
  String get summary =>
      '$name · ${ClockTime.minutes(fields['startMinute'] as int)} – ${ClockTime.minutes(fields['endMinute'] as int)}${(fields['endMinute'] as int) <= (fields['startMinute'] as int) ? ' (ends next day)' : ''} · $timezone';
}
