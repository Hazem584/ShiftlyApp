import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_loaded_body.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_loading.dart';

class EmployeeDetailsView extends StatelessWidget {
  const EmployeeDetailsView({
    super.key,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
  });
  final String workspaceId;
  final String membershipId;
  final String timezone;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Employee details'))),
    body: BlocBuilder<EmployeeDetailsCubit, EmployeeDetailsState>(
      builder: (context, state) => switch (state) {
        EmployeeDetailsLoadingState() => const EmployeeDetailsLoading(),
        EmployeeDetailsErrorState(:final message) => EmptyState(
          icon: Icons.person_search_outlined,
          title: context.tr('Employee unavailable'),
          message: message,
          action: FilledButton(
            onPressed: () => context.read<EmployeeDetailsCubit>().load(
              workspaceId: workspaceId,
              membershipId: membershipId,
            ),
            child: Text(context.tr('Retry')),
          ),
        ),
        EmployeeDetailsLoadedState(:final employee) =>
          EmployeeDetailsLoadedBody(
            employee: employee,
            workspaceId: workspaceId,
            membershipId: membershipId,
            timezone: timezone,
          ),
      },
    ),
  );
}
