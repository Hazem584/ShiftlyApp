import 'package:flutter/material.dart';

import '../../data/fixed_shift_repository.dart';
import '../cubit/extra_shifts_cubit.dart';
import 'extra_shift_form_state.dart';

class ExtraShiftForm extends StatefulWidget {
  const ExtraShiftForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.actual,
    super.key,
  });
  final FixedShiftRepository repository;
  final ExtraShiftsCubit cubit;
  final String workspaceId, timezone;
  final bool actual;
  @override
  State<ExtraShiftForm> createState() => ExtraShiftFormState();
}
