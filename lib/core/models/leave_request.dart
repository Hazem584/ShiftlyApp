import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/attendance_request.dart';

enum LeaveRequestType { leave, earlyDeparture }

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  final String id;
  final String employeeId;
  final LeaveRequestType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final RequestStatus status;

  @override
  List<Object?> get props => [
    id,
    employeeId,
    type,
    startDate,
    endDate,
    reason,
    status,
  ];
}
