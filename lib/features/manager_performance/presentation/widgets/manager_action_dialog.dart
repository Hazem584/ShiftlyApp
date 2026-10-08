import 'package:flutter/material.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../cubit/manager_performance_cubit.dart';
import 'manager_action_dialog_state.dart';
import 'manager_form_field.dart';

class ManagerActionDialog extends StatefulWidget {
  const ManagerActionDialog({
    required this.title,
    required this.fields,
    required this.cubit,
    required this.scope,
    this.initial = const {},
    this.afterDate,
    super.key,
  });
  final String title;
  final List<ManagerFormField> fields;
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope scope;
  final Map<String, Object?> initial;
  final String? afterDate;
  @override
  State<ManagerActionDialog> createState() => ManagerActionDialogState();
}
