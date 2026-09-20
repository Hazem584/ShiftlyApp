import 'package:shiftly/core/models/attendance_request.dart';
import 'package:shiftly/core/models/leave_request.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

class MockLeaveRequestRepository implements LeaveRequestRepository {
  MockLeaveRequestRepository({this.delay = Duration.zero})
    : _requests = [
        LeaveRequest(
          id: 'leave-1',
          employeeId: 'emp-1',
          employeeName: 'Mariam Hassan',
          type: LeaveRequestType.leave,
          startDate: DateTime(2026, 9, 24),
          endDate: DateTime(2026, 9, 26),
          reason: 'Family event outside the city.',
          status: RequestStatus.pending,
          submittedAt: DateTime(2026, 9, 20, 9, 45),
        ),
        LeaveRequest(
          id: 'leave-2',
          employeeId: 'emp-2',
          employeeName: 'Omar Khaled',
          type: LeaveRequestType.earlyDeparture,
          startDate: DateTime(2026, 9, 22),
          endDate: DateTime(2026, 9, 22),
          reason: 'Medical appointment at 3:30 PM.',
          status: RequestStatus.pending,
          submittedAt: DateTime(2026, 9, 19, 14, 10),
        ),
        LeaveRequest(
          id: 'leave-3',
          employeeId: 'emp-3',
          employeeName: 'Nour Adel',
          type: LeaveRequestType.leave,
          startDate: DateTime(2026, 9, 15),
          endDate: DateTime(2026, 9, 15),
          reason: 'Personal day.',
          status: RequestStatus.approved,
          submittedAt: DateTime(2026, 9, 12, 11, 30),
          reviewedAt: DateTime(2026, 9, 12, 12, 5),
        ),
      ];

  final Duration delay;
  final List<LeaveRequest> _requests;

  @override
  Future<List<LeaveRequest>> getRequests() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return List.unmodifiable(_requests);
  }

  @override
  Future<LeaveRequest> updateStatus(String id, RequestStatus status) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final index = _requests.indexWhere((request) => request.id == id);
    if (index < 0) throw StateError('Request not found');
    final updated = _requests[index].copyWith(
      status: status,
      reviewedAt: DateTime.now(),
    );
    _requests[index] = updated;
    return updated;
  }
}
