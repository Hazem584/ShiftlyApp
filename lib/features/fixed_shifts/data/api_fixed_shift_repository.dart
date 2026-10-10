import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/legacy_clock_in_repository.dart';

import 'fixed_shift_intent_store.dart';

class ApiFixedShiftRepository
    implements
        FixedShiftRepository,
        ExtraShiftRepository,
        LegacyClockInRepository {
  ApiFixedShiftRepository(this._dio, this._preferences);

  final Dio _dio;
  final SharedPreferences _preferences;
  late final _intents = FixedShiftIntentStore(
    _preferences,
    findPendingAttendance,
  );

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
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/work-patterns',
      queryParameters: {'page': page, 'limit': limit},
    );
    final json = ApiModelParser.map(response.data);
    final currentJson = ApiModelParser.optionalMap(json['current'], 'current');
    return WorkPatternHistory(
      pagination: ApiPagination.fromJson(
        ApiModelParser.map(json['pagination']),
      ),
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
    required String shiftTemplateId,
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
      data: {
        'shiftTemplateId': shiftTemplateId,
        'expectedWeekdays': unique,
        'effectiveFrom': effectiveFrom,
      },
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
      status: ApiModelParser.optionalString(json['status']) ?? 'UNKNOWN',
      openAttendanceId: json['openAttendance'] == null
          ? null
          : ApiModelParser.string(
              ApiModelParser.map(json['openAttendance']),
              'id',
            ),
      authorizedOccurrences:
          (json['authorizedOccurrences'] == null
                  ? <Object?>[]
                  : ApiModelParser.list(
                      json['authorizedOccurrences'],
                      'authorizedOccurrences',
                    ))
              .map(
                (v) => EligibleShiftOccurrence.fromJson(ApiModelParser.map(v)),
              )
              .toList(),
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
        if (response.data == null) {
          return null;
        }
        return FlexibleAttendance.fromJson(ApiModelParser.map(response.data));
      });

  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
  }) => _attendance(
    () => _dio.post<Object?>(
      '/attendance/flexible/clock-in',
      data: {
        'workspaceId': workspaceId,
        'shiftTemplateId': shiftTemplateId,
        'clientAttendanceId': clientAttendanceId,
        'assignmentId': ?assignmentId,
        'extraAuthorizationId': ?extraAuthorizationId,
      },
    ),
  );

  @override
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId) =>
      _attendance(
        () => _dio.post<Object?>('/attendance/$attendanceId/clock-out'),
      );

  @override
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) => _intents.loadPendingClockIn(
    userId: userId,
    workspaceId: workspaceId,
    membershipId: membershipId,
    templateId: templateId,
  );

  @override
  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  ) => _intents.inspectLegacyClockIns(scope);

  @override
  Future<FlexibleAttendance?> findPendingAttendance(PendingClockIn value) =>
      _request(() async {
        var page = 1;
        while (true) {
          final response = await _dio.get<Object?>(
            '/attendance/me',
            queryParameters: {
              'workspaceId': value.workspaceId,
              'page': page,
              'limit': 100,
            },
          );
          final json = ApiModelParser.map(response.data);
          final records = ApiModelParser.list(json['data'], 'data');
          for (final item in records) {
            final record = ApiModelParser.map(item);
            if (record['clientAttendanceId'] == value.clientAttendanceId &&
                record['employeeMembershipId'] == value.membershipId) {
              return FlexibleAttendance.fromJson(record);
            }
          }
          final pagination = ApiPagination.fromJson(
            ApiModelParser.map(json['pagination']),
          );
          if (page >= pagination.totalPages) {
            return null;
          }
          page++;
        }
      });
  @override
  Future<void> savePendingClockIn(PendingClockIn value) =>
      _intents.savePendingClockIn(value);

  @override
  Future<void> clearPendingClockIn(PendingClockIn value) =>
      _intents.clearPendingClockIn(value);

  @override
  Future<ExtraAuthorizationPage> listExtras(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/extra-shifts',
      queryParameters: {'page': page, 'limit': limit},
    );
    final json = ApiModelParser.map(response.data);
    return ExtraAuthorizationPage(
      ApiModelParser.list(
        json['data'],
        'data',
      ).map((v) => ExtraAuthorization(ApiModelParser.map(v))).toList(),
      ApiPagination.fromJson(ApiModelParser.map(json['pagination'])),
    );
  });
  @override
  Future<ExtraAuthorization> createExtra(
    String workspaceId,
    String membershipId,
    Map<String, Object?> payload, {
    required bool actual,
  }) => _request(() async {
    final response = await _dio.post<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/extra-shifts${actual ? '/attendance' : ''}',
      data: payload,
    );
    return ExtraAuthorization(ApiModelParser.map(response.data));
  });
  @override
  Future<ExtraAuthorization> revokeExtra(
    String workspaceId,
    String membershipId,
    String authorizationId,
  ) => _request(() async {
    final response = await _dio.delete<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/extra-shifts/$authorizationId',
    );
    return ExtraAuthorization(ApiModelParser.map(response.data));
  });

  @override
  Future<String?> readExtraIntent(FeatureSessionScope scope) =>
      _intents.readExtraIntent(scope);
  @override
  Future<void> saveExtraIntent(FeatureSessionScope scope, String intent) =>
      _intents.saveExtraIntent(scope, intent);

  @override
  Future<void> clearExtraIntent(FeatureSessionScope scope, String intent) =>
      _intents.clearExtraIntent(scope, intent);

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
      throw ApiErrorParser.parse(error);
    }
  }
}
