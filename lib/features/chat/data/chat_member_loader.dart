import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

Future<List<Employee>> loadActiveChatMembers(
  EmployeeRepository repository,
  FeatureSessionScope scope,
) async {
  const limit = 50;
  var pageNumber = 1;
  var totalPages = 1;
  final byMembershipId = <String, Employee>{};
  do {
    final page = await repository.listEmployees(
      workspaceId: scope.workspaceId,
      status: EmployeeStatusFilter.active,
      page: pageNumber,
      limit: limit,
    );
    for (final employee in page.data) {
      if (employee.employmentStatus == EmploymentStatus.active) {
        byMembershipId[employee.id] = employee;
      }
    }
    totalPages = page.totalPages;
    pageNumber++;
  } while (pageNumber <= totalPages);
  final members = byMembershipId.values.toList(growable: false);
  members.sort((a, b) => a.displayName.compareTo(b.displayName));
  return members;
}
