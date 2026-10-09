import 'package:flutter/material.dart';

import '../../data/fixed_shift_repository.dart';
import '../cubit/fixed_shifts_cubit.dart';
import 'assignment_form_state.dart';

class AssignmentForm extends StatefulWidget {
  const AssignmentForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    super.key,
  });
  final FixedShiftRepository repository;
  final WorkPatternCubit cubit;
  final String workspaceId, timezone;
  @override
  State<AssignmentForm> createState() => AssignmentFormState();
}
