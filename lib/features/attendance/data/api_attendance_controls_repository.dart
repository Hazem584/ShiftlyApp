import 'package:dio/dio.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';

class ApiAttendanceControlsRepository implements AttendanceControlsRepository {
  ApiAttendanceControlsRepository(this.dio);
  final Dio dio;
  @override
  Future<void> decideMonth({
    required String workspaceId,
    required int year,
    required int month,
    required int revision,
    required bool close,
    required String reason,
  }) async {
    await dio.patch<Object?>(
      '/workspaces/$workspaceId/attendance-controls/month',
      data: {
        'year': year,
        'month': month,
        'revision': revision,
        'action': close ? 'CLOSE' : 'REOPEN',
        'reason': reason,
      },
    );
  }

  @override
  Future<void> decideDay({
    required String workspaceId,
    required String employeeMembershipId,
    required String date,
    required String status,
    required String reason,
    required int revision,
  }) async {
    await dio.patch<Object?>(
      '/workspaces/$workspaceId/attendance-controls/day',
      data: {
        'employeeMembershipId': employeeMembershipId,
        'operationalDate': date,
        'status': status,
        'reason': reason,
        'revision': revision,
      },
    );
  }
}
