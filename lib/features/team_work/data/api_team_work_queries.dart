import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

import 'api_team_work_payloads.dart';

String teamWorkBasePath(String workspaceId) =>
    '/workspaces/$workspaceId/team-work';

Future<T> runTeamWorkRequest<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (error) {
    throw ApiErrorParser.parse(error);
  }
}

Future<WorkPage<WorkTask>> fetchWorkTasks(Dio dio, String workspaceId) =>
    runTeamWorkRequest(
      () async => parseWorkTasksPage(
        (await dio.get<Object?>('${teamWorkBasePath(workspaceId)}/tasks')).data,
      ),
    );

Future<CorrectionRequest> fetchCorrectionById(
  Dio dio,
  String workspaceId,
  String id,
) => runTeamWorkRequest(
  () async => CorrectionRequest.fromJson(
    workMap(
      (await dio.get<Object?>(
        '${teamWorkBasePath(workspaceId)}/corrections/$id',
      )).data,
    ),
  ),
);

Future<WorkPage<CorrectionRequest>> fetchCorrectionsPage(
  Dio dio,
  String workspaceId, {
  required int page,
  String? status,
}) => runTeamWorkRequest(
  () async => WorkPage.fromJson(
    (await dio.get<Object?>(
      '${teamWorkBasePath(workspaceId)}/corrections',
      queryParameters: {'page': page, 'status': ?status},
    )).data,
    CorrectionRequest.fromJson,
  ),
);

Future<WorkPage<TeamAnnouncement>> fetchAnnouncementsPage(
  Dio dio,
  String workspaceId, {
  required int page,
  required bool pendingOnly,
}) => runTeamWorkRequest(
  () async => WorkPage.fromJson(
    (await dio.get<Object?>(
      '${teamWorkBasePath(workspaceId)}/announcements',
      queryParameters: {'page': page, if (pendingOnly) 'pendingOnly': true},
    )).data,
    TeamAnnouncement.fromJson,
  ),
);
