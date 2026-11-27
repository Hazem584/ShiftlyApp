import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_extra_client.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_parsers.dart';
import 'package:shiftly/features/fixed_shifts/data/api_template_eligibility_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_intent_store.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class ApiFixedShiftRepository extends ApiFixedShiftExtraAndIntentClient {
  ApiFixedShiftRepository(this.dio, this._preferences);
  @override
  final Dio dio;
  final SharedPreferences _preferences;
  @override
  late final intents = FixedShiftIntentStore(
    _preferences,
    findPendingAttendance,
  );

  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) => requestFixedShift(() async {
    final res = await dio.get<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/work-patterns',
      queryParameters: {'page': page, 'limit': limit},
    );
    return parseWorkPatternHistory(res.data);
  });

  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required String shiftTemplateId,
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) => requestFixedShift(() async {
    final unique = validateExpectedWeekdays(expectedWeekdays);
    final res = await dio.post<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/work-patterns',
      data: {
        'shiftTemplateId': shiftTemplateId,
        'expectedWeekdays': unique,
        'effectiveFrom': effectiveFrom,
      },
    );
    return WorkPattern.fromJson(ApiModelParser.map(res.data));
  });

  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) =>
      requestFixedShift(() async {
        final res = await dio.get<Object?>(
          '/shift-templates/eligibility',
          queryParameters: {'workspaceId': workspaceId},
        );
        return parseTemplateEligibility(res.data);
      });

  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) =>
      requestFixedShift(() async {
        final res = await dio.get<Object?>(
          '/attendance/me/current',
          queryParameters: {'workspaceId': workspaceId},
        );
        return res.data == null
            ? null
            : FlexibleAttendance.fromJson(ApiModelParser.map(res.data));
      });

  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
    AttendanceLocationPoint? location,
  }) => _attendance(
    () => dio.post<Object?>(
      '/attendance/flexible/clock-in',
      data: {
        'workspaceId': workspaceId,
        'shiftTemplateId': shiftTemplateId,
        'clientAttendanceId': clientAttendanceId,
        'assignmentId': ?assignmentId,
        'extraAuthorizationId': ?extraAuthorizationId,
        if (location != null) 'location': location.toJson(),
      },
    ),
  );

  @override
  Future<FlexibleAttendance> flexibleClockOut(
    String attendanceId, {
    AttendanceLocationPoint? location,
  }) => _attendance(
    () => dio.post<Object?>(
      '/attendance/$attendanceId/clock-out',
      data: location == null ? null : {'location': location.toJson()},
    ),
  );

  Future<FlexibleAttendance> _attendance(
    Future<Response<Object?>> Function() op,
  ) => requestFixedShift(
    () async =>
        FlexibleAttendance.fromJson(ApiModelParser.map((await op()).data)),
  );
}
