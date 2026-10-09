import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_list_employee_card.dart';

class EmployeeList extends StatelessWidget {
  const EmployeeList({
    required this.employees,
    required this.onRefresh,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    super.key,
  });
  final List<Employee> employees;
  final RefreshCallback onRefresh;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.ink,
    onRefresh: onRefresh,
    child: ListView.separated(
      key: const Key('employee-list'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      itemCount: employees.length + ((hasMore || loadingMore) ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        if (index < employees.length) {
          return EmployeeListEmployeeCard(employee: employees[index]);
        }
        return Center(
          child: loadingMore
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                )
              : TextButton.icon(
                  key: const Key('load-more-employees'),
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
        );
      },
    ),
  );
}
