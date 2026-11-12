import 'package:flutter/material.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';

import 'employee_page.dart';

class EmployeeCorrectionDetailsScreen extends StatelessWidget {
  const EmployeeCorrectionDetailsScreen({
    required this.request,
    required this.timezone,
    super.key,
  });
  final CorrectionRequest request;
  final String timezone;
  @override
  Widget build(BuildContext context) => EmployeePage(
    title: 'Request correction details',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CorrectionRequestCard(
          request: request,
          timezone: timezone,
          detailed: true,
        ),
      ],
    ),
  );
}
