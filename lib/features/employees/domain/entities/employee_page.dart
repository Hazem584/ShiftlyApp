import 'package:shiftly/core/models/employee.dart';

class EmployeePage {
  const EmployeePage({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Employee> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
