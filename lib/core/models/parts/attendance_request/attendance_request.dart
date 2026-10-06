part of '../../attendance_request.dart';

class AttendanceRequest extends Equatable {
  const AttendanceRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.requestedAt,
    required this.status,
  });

  final String id;
  final String employeeId;
  final AttendanceRequestType type;
  final DateTime requestedAt;
  final RequestStatus status;

  @override
  List<Object?> get props => [id, employeeId, type, requestedAt, status];
}
