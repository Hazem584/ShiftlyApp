import 'package:shiftly/core/models/attendance_request.dart';
import 'package:shiftly/core/models/leave_request.dart';

abstract interface class LeaveRequestRepository {
  Future<List<LeaveRequest>> getRequests();
  Future<LeaveRequest> updateStatus(String id, RequestStatus status);
}
