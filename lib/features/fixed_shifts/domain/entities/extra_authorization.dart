import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/saved_schedule.dart';
import 'package:shiftly/features/fixed_shifts/domain/services/fixed_shift_dates.dart';

class ExtraAuthorization {
  ExtraAuthorization(Map<String, Object?> fields)
    : fields = Map.unmodifiable(fields),
      schedule = SavedSchedule(
        ApiModelParser.map(fields['occurrenceSnapshot']),
      ) {
    for (final key in [
      'id',
      'workspaceId',
      'employeeMembershipId',
      'shiftTemplateId',
      'clientAuthorizationId',
      'createdByMembershipId',
      'reason',
      'explanation',
    ]) {
      ApiModelParser.string(fields, key);
    }
    ApiModelParser.date(fields, 'createdAt');
    fixedShiftOperationalDate(fields, 'operationalDate');
    for (final key in [
      'actualClockInAt',
      'actualClockOutAt',
      'consumedAt',
      'revokedAt',
    ]) {
      ApiModelParser.optionalDate(fields[key]);
    }
    // List and revoke responses contain the authorization only. Creation of
    // actual attendance still requires linked evidence in ExtraShiftsCubit.
    if (fields.containsKey('attendance')) {
      ApiModelParser.list(fields['attendance'], 'attendance');
    }
  }
  final Map<String, Object?> fields;
  final SavedSchedule schedule;
  List<Object?> get attendance => fields.containsKey('attendance')
      ? ApiModelParser.list(fields['attendance'], 'attendance')
      : const [];
  String get id => fields['id'] as String;
  String get status =>
      ApiModelParser.optionalString(fields['status']) ?? 'UNKNOWN';
  bool get canRevoke => status == 'AUTHORIZED';
  String get operationalDate =>
      fixedShiftOperationalDate(fields, 'operationalDate');
}
