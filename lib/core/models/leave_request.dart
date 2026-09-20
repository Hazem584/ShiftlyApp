import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/attendance_request.dart';

enum LeaveRequestType { leave, earlyDeparture }

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final LeaveRequestType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final RequestStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  String get employeeInitials => employeeName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  LeaveRequest copyWith({RequestStatus? status, DateTime? reviewedAt}) =>
      LeaveRequest(
        id: id,
        employeeId: employeeId,
        employeeName: employeeName,
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: status ?? this.status,
        submittedAt: submittedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    type,
    startDate,
    endDate,
    reason,
    status,
    submittedAt,
    reviewedAt,
  ];
}
