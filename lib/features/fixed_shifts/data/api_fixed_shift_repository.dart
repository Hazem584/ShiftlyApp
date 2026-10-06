import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';

class ApiFixedShiftRepository implements FixedShiftRepository {
  ApiFixedShiftRepository(this._dio, this._preferences);

  static const _pendingKey = 'fixed_shift.pending_clock_in.v1';
  final Dio _dio;
  final SharedPreferences _preferences;

  @override
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  }) => _page(
    () => _dio.get<Object?>(
      '/workspaces/$workspaceId/shift-templates',
      queryParameters: {
        'page': page,
        'limit': limit,
        'includeArchived': includeArchived,
      },
    ),
  );

  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) => _page(
    () => _dio.get<Object?>(
      '/shift-templates/me',
      queryParameters: {
        'workspaceId': workspaceId,
        'page': page,
        'limit': limit,
      },
    ),
  );

  @override
  Future<ShiftTemplate> getTemplate(String workspaceId, String templateId) =>
      _template(
        () => _dio.get<Object?>(
          '/workspaces/$workspaceId/shift-templates/$templateId',
        ),
      );

  @override
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  ) => _template(
    () => _dio.post<Object?>(
      '/workspaces/$workspaceId/shift-templates',
      data: input.toJson(),
    ),
  );

  @override
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  ) => _template(
    () => _dio.patch<Object?>(
      '/workspaces/$workspaceId/shift-templates/$templateId',
      data: input.toJson(),
    ),
  );

  @override
  Future<ShiftTemplate> archiveTemplate(
    String workspaceId,
    String templateId,
  ) => _template(
    () => _dio.delete<Object?>(
      '/workspaces/$workspaceId/shift-templates/$templateId',
    ),
  );

  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/work-patterns',
    );
    final json = ApiModelParser.map(response.data);
    final currentJson = ApiModelParser.optionalMap(json['current'], 'current');
    return WorkPatternHistory(
      current: currentJson == null ? null : WorkPattern.fromJson(currentJson),
      history: ApiModelParser.list(json['history'], 'history')
          .map((value) => WorkPattern.fromJson(ApiModelParser.map(value)))
          .toList(growable: false),
    );
  });

  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) => _request(() async {
    final unique = expectedWeekdays.toSet().toList()..sort();
    if (unique.length != expectedWeekdays.length ||
        unique.isEmpty ||
        unique.any((value) => value < 0 || value > 6)) {
      throw const FormatException('Invalid expected weekdays');
    }
    final response = await _dio.post<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/work-patterns',
      data: {'expectedWeekdays': unique, 'effectiveFrom': effectiveFrom},
    );
    return WorkPattern.fromJson(ApiModelParser.map(response.data));
  });

  @override
  Future<TemplateEligibility> getEligibility(
    String workspaceId,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/shift-templates/eligibility',
      queryParameters: {'workspaceId': workspaceId},
    );
    final json = ApiModelParser.map(response.data);
    final recommendedJson = ApiModelParser.optionalMap(
      json['recommended'],
      'recommended',
    );
    return TemplateEligibility(
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      timezone: ApiModelParser.string(json, 'timezone'),
      evaluatedAt: ApiModelParser.date(json, 'evaluatedAt'),
      recommended: recommendedJson == null
          ? null
          : EligibleShiftOccurrence.fromJson(recommendedJson),
      eligibleTemplates:
          ApiModelParser.list(json['eligibleTemplates'], 'eligibleTemplates')
              .map(
                (value) =>
                    EligibleShiftOccurrence.fromJson(ApiModelParser.map(value)),
              )
              .toList(growable: false),
    );
  });

  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/attendance/me/current',
          queryParameters: {'workspaceId': workspaceId},
        );
        if (response.data == null) return null;
        return FlexibleAttendance.fromJson(ApiModelParser.map(response.data));
      });

  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
  }) => _attendance(
    () => _dio.post<Object?>(
      '/attendance/flexible/clock-in',
      data: {
        'workspaceId': workspaceId,
        'shiftTemplateId': shiftTemplateId,
        'clientAttendanceId': clientAttendanceId,
      },
    ),
  );

  @override
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId) =>
      _attendance(
        () => _dio.post<Object?>('/attendance/$attendanceId/clock-out'),
      );

  @override
  Future<PendingClockIn?> loadPendingClockIn() async {
    final raw = _preferences.getString(_pendingKey);
    if (raw == null) return null;
    try {
      final json = ApiModelParser.map(jsonDecode(raw));
      return PendingClockIn(
        userId: ApiModelParser.string(json, 'userId'),
        workspaceId: ApiModelParser.string(json, 'workspaceId'),
        membershipId: ApiModelParser.string(json, 'membershipId'),
        templateId: ApiModelParser.string(json, 'templateId'),
        clientAttendanceId: ApiModelParser.string(json, 'clientAttendanceId'),
      );
    } catch (_) {
      await clearPendingClockIn();
      return null;
    }
  }

  @override
  Future<void> savePendingClockIn(PendingClockIn value) async {
    await _preferences.setString(
      _pendingKey,
      jsonEncode({
        'userId': value.userId,
        'workspaceId': value.workspaceId,
        'membershipId': value.membershipId,
        'templateId': value.templateId,
        'clientAttendanceId': value.clientAttendanceId,
      }),
    );
  }

  @override
  Future<void> clearPendingClockIn() async {
    await _preferences.remove(_pendingKey);
  }

  Future<ShiftTemplate> _template(
    Future<Response<Object?>> Function() operation,
  ) => _request(() async {
    final response = await operation();
    return ShiftTemplate.fromJson(ApiModelParser.map(response.data));
  });

  Future<FlexibleAttendance> _attendance(
    Future<Response<Object?>> Function() operation,
  ) => _request(() async {
    final response = await operation();
    return FlexibleAttendance.fromJson(ApiModelParser.map(response.data));
  });

  Future<ShiftTemplatePage> _page(
    Future<Response<Object?>> Function() operation,
  ) => _request(() async {
    final response = await operation();
    final json = ApiModelParser.map(response.data);
    return ShiftTemplatePage(
      data: ApiModelParser.list(json['data'], 'data')
          .map((value) => ShiftTemplate.fromJson(ApiModelParser.map(value)))
          .toList(growable: false),
      pagination: ApiPagination.fromJson(
        ApiModelParser.map(json['pagination'], 'pagination'),
      ),
    );
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(
        error is DioException && error.error != null ? error.error! : error,
      );
    }
  }
}
