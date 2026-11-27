import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/attendance_status.dart';
import 'package:shiftly/core/models/employee_role.dart';
import 'package:shiftly/core/models/employment_status.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';

export 'package:shiftly/core/models/attendance_status.dart';
export 'package:shiftly/core/models/employee_role.dart';
export 'package:shiftly/core/models/employment_status.dart';

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
    this.profileId = '',
    this.avatarUrl,
    this.role = EmployeeRole.employee,
    this.monthlySalary,
    this.hourlyRate,
    this.payrollWorkDays = 26,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? jobTitle;
  final WorkLocation? location;
  final Shift? shift;
  final DateTime? startDate;
  final EmploymentStatus employmentStatus;
  final AttendanceStatus attendanceStatus;
  final String profileId;
  final String? avatarUrl;
  final EmployeeRole role;
  final double? monthlySalary;
  final double? hourlyRate;
  final int payrollWorkDays;
  double? get dailyRate =>
      monthlySalary == null ? null : monthlySalary! / payrollWorkDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double effectiveHourlyRate([int standardHours = 176]) =>
      hourlyRate ??
      (monthlySalary != null && standardHours > 0
          ? monthlySalary! / standardHours
          : 0);

  String get displayName => fullName ?? 'Unnamed employee';
  String get displayEmail => email ?? 'Not provided';
  String get displayPhone => phone ?? 'Not provided';
  String get displayJobTitle => jobTitle ?? 'No job title';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
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
    profileId,
    avatarUrl,
    role,
    monthlySalary,
    hourlyRate,
    payrollWorkDays,
    createdAt,
    updatedAt,
  ];
}
