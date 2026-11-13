import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';

class TaskProgressOverview extends StatelessWidget {
  const TaskProgressOverview({
    required this.open,
    required this.done,
    super.key,
  });
  final int? open, done;
  @override
  Widget build(BuildContext context) {
    final known = open != null && done != null,
        total = (open ?? 0) + (done ?? 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? EmployeeDesign.heroDark
            : EmployeeDesign.hero,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            open == null
                ? context.tr('Your personal tasks')
                : context.tr('{count} tasks remaining', {'count': '$open'}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done == null
                ? context.tr('One small step at a time.')
                : context.tr('{count} completed', {'count': '$done'}),
            style: const TextStyle(
              color: EmployeeDesign.heroText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          if (known)
            LinearProgressIndicator(
              value: total == 0 ? 1 : done! / total,
              minHeight: 4,
              color: EmployeeDesign.mint,
              backgroundColor: const Color(0xFF414966),
              borderRadius: BorderRadius.circular(8),
            ),
        ],
      ),
    );
  }
}
