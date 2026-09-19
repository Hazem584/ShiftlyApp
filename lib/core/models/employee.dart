import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';

enum EmploymentStatus { active, onLeave, inactive }

enum AttendanceStatus { present, absent, late, notStarted }

class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.jobTitle,
    required this.location,
    required this.shift,
    required this.startDate,
    required this.employmentStatus,
    this.attendanceStatus = AttendanceStatus.notStarted,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String jobTitle;
  final WorkLocation location;
  final Shift shift;
  final DateTime startDate;
  final EmploymentStatus employmentStatus;
  final AttendanceStatus attendanceStatus;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    phone,
    email,
    jobTitle,
    location,
    shift,
    startDate,
    employmentStatus,
    attendanceStatus,
  ];
}
