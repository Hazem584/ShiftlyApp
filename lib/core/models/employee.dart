import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';

enum EmploymentStatus { active, suspended, onLeave, unknown }

enum EmployeeRole { employee, manager, unknown }

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
    this.profileId = '',
    this.avatarUrl,
    this.role = EmployeeRole.employee,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    createdAt,
    updatedAt,
  ];
}
