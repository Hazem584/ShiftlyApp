import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.occurredAt,
    required this.isCheckIn,
    this.isLate = false,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime occurredAt;
  final bool isCheckIn;
  final bool isLate;

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    occurredAt,
    isCheckIn,
    isLate,
  ];
}
