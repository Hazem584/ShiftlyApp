import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1000 &&
                MediaQuery.textScalerOf(context).scale(14) < 22
            ? 2
            : 1;
        final rows = (employees.length / columns).ceil();
        return ListView.separated(
          key: const Key('employee-list'),
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
          itemCount: rows + ((hasMore || loadingMore) ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            if (index < rows) {
              if (columns == 1) {
                return EmployeeListEmployeeCard(employee: employees[index]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: EmployeeListEmployeeCard(
                      employee: employees[index * 2],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: index * 2 + 1 < employees.length
                        ? EmployeeListEmployeeCard(
                            employee: employees[index * 2 + 1],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
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
                      label: Text(context.tr('Load more')),
                    ),
            );
          },
        );
      },
    ),
  );
}
