import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class ApiTeamWorkRepository implements TeamWorkRepository {
  ApiTeamWorkRepository(this._dio);
  final Dio _dio;
  String _base(String workspaceId) => '/workspaces/$workspaceId/team-work';
  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<WorkPage<WorkTask>> tasks(String workspaceId) => _request(() async {
    final json = workMap(
      (await _dio.get<Object?>('${_base(workspaceId)}/tasks')).data,
    );
    final items = (json['data'] as List)
        .map((e) => WorkTask.fromJson(workMap(e)))
        .toList();
    return WorkPage(
      items,
      items.length,
      notice: json['scheduleUnavailable'] == true
          ? 'Some shift schedules need review. Open shifts to check assignments.'
          : json['truncated'] == true
          ? 'More items need attention. Open attendance or requests to see the complete list.'
          : null,
    );
  });
  @override
  Future<CorrectionRequest> correction(String workspaceId, String id) =>
      _request(
        () async => CorrectionRequest.fromJson(
          workMap(
            (await _dio.get<Object?>('${_base(workspaceId)}/corrections/$id'))
                .data,
          ),
        ),
      );
  @override
  Future<WorkPage<CorrectionRequest>> corrections(
    String workspaceId, {
    int page = 1,
    String? status,
  }) => _request(
    () async => WorkPage.fromJson(
      (await _dio.get<Object?>(
        '${_base(workspaceId)}/corrections',
        queryParameters: {'page': page, 'status': ?status},
      )).data,
      CorrectionRequest.fromJson,
    ),
  );
  @override
  Future<void> requestCorrection(
    String workspaceId, {
    required String attendanceId,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) => _request(() async {
    await _dio.post<Object?>(
      '${_base(workspaceId)}/corrections',
      data: {
        'attendanceId': attendanceId,
        'clockInAt': clockIn.toUtc().toIso8601String(),
        'clockOutAt': clockOut.toUtc().toIso8601String(),
        'reason': reason.trim(),
      },
    );
  });
  @override
  Future<void> reviewCorrection(
    String workspaceId,
    String id, {
    required bool approve,
    String? note,
  }) => _request(() async {
    await _dio.post<Object?>(
      '${_base(workspaceId)}/corrections/$id/review',
      data: {'decision': approve ? 'APPROVED' : 'REJECTED', 'note': ?note},
    );
  });
  @override
  Future<WorkPage<TeamAnnouncement>> announcements(
    String workspaceId, {
    int page = 1,
    bool pendingOnly = false,
  }) => _request(
    () async => WorkPage.fromJson(
      (await _dio.get<Object?>(
        '${_base(workspaceId)}/announcements',
        queryParameters: {'page': page, if (pendingOnly) 'pendingOnly': true},
      )).data,
      TeamAnnouncement.fromJson,
    ),
  );
  @override
  Future<void> publish(
    String workspaceId, {
    required String clientId,
    required String title,
    required String body,
    required bool acknowledgment,
  }) => _request(() async {
    await _dio.post<Object?>(
      '${_base(workspaceId)}/announcements',
      data: {
        'clientId': clientId,
        'title': title.trim(),
        'body': body.trim(),
        'requiresAcknowledgment': acknowledgment,
      },
    );
  });
  @override
  Future<void> markAnnouncement(
    String workspaceId,
    String id, {
    bool acknowledge = false,
  }) => _request(() async {
    await _dio.post<Object?>(
      '${_base(workspaceId)}/announcements/$id/${acknowledge ? 'acknowledge' : 'read'}',
    );
  });
  @override
  Future<List<AnnouncementReader>> readers(String workspaceId, String id) =>
      _request(() async {
        final json = workMap(
          (await _dio.get<Object?>(
            '${_base(workspaceId)}/announcements/$id/receipts',
          )).data,
        );
        return (json['data'] as List)
            .map((e) => AnnouncementReader.fromJson(workMap(e)))
            .toList();
      });
}
