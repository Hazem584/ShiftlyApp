import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/models/work_location.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

final mockWorkLocations = [
  const WorkLocation(
    id: 'main',
    name: 'Shift Lab – Main Branch',
    address: 'Cairo',
  ),
  const WorkLocation(
    id: 'west',
    name: 'Shift Lab – West Branch',
    address: 'Giza',
  ),
];

final mockShifts = [
  Shift(
    id: 'morning',
    name: 'Morning Shift',
    startTime: DateTime(2026, 1, 1, 8),
    endTime: DateTime(2026, 1, 1, 16),
  ),
  Shift(
    id: 'evening',
    name: 'Evening Shift',
    startTime: DateTime(2026, 1, 1, 16),
    endTime: DateTime(2026, 1, 2),
  ),
];

Employee copyEmployeeWithStatus(Employee c, EmployeeStatusFilter status) =>
    Employee(
      id: c.id,
      profileId: c.profileId,
      fullName: c.fullName,
      phone: c.phone,
      email: c.email,
      jobTitle: c.jobTitle,
      location: c.location,
      shift: c.shift,
      startDate: c.startDate,
      employmentStatus: status == EmployeeStatusFilter.active
          ? EmploymentStatus.active
          : EmploymentStatus.suspended,
      attendanceStatus: c.attendanceStatus,
      avatarUrl: c.avatarUrl,
      role: c.role,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );

EmployeePage paginateMockEmployees(
  List<Employee> all, {
  required EmployeeStatusFilter? status,
  required int page,
  required int limit,
}) {
  final matches = all
      .where(
        (e) => switch (status) {
          EmployeeStatusFilter.active =>
            e.employmentStatus == EmploymentStatus.active,
          EmployeeStatusFilter.suspended =>
            e.employmentStatus == EmploymentStatus.suspended,
          null => true,
        },
      )
      .toList(growable: false);
  final start = (page - 1) * limit;
  final data = start >= matches.length
      ? const <Employee>[]
      : matches.sublist(start, (start + limit).clamp(0, matches.length));
  return EmployeePage(
    data: data,
    page: page,
    limit: limit,
    total: matches.length,
    totalPages: (matches.length / limit).ceil(),
  );
}
