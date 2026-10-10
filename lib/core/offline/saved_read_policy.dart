import 'package:dio/dio.dart';

import 'read_sync_state.dart';

abstract final class SavedReadPolicy {
  static ReadCategory? category(RequestOptions request, String workspaceId) {
    if (request.method != 'GET' || request.extra['requireFresh'] == true) {
      return null;
    }
    final path = request.path;
    // Recovery lookups and live clock-in eligibility must always reach the API.
    if (request.queryParameters.containsKey('clientAttendanceId')) return null;
    final personal = const {
      '/shifts/me': ReadCategory.schedule,
      '/attendance/me': ReadCategory.attendance,
      '/shift-templates/me': ReadCategory.schedule,
    };
    if (personal.containsKey(path)) {
      return request.queryParameters['workspaceId'] == workspaceId
          ? personal[path]
          : null;
    }
    final root = '/workspaces/$workspaceId/';
    if (!path.startsWith(root)) return null;
    final resource = path.substring(root.length);
    if (resource == 'shifts' || resource == 'shift-templates') {
      return ReadCategory.schedule;
    }
    if (resource == 'attendance' ||
        resource == 'attendance/requests' ||
        resource == 'leave-requests') {
      return ReadCategory.attendance;
    }
    return null;
  }

  static bool connectionFailure(DioException error) =>
      const {
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      }.contains(error.type) &&
      error.response == null;
}
