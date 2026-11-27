import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../application/tasks_cubit.dart';
import '../../domain/personal_task.dart';
import '../task_actions.dart';

String? validateTaskEditorDates({
  required BuildContext context,
  required PersonalTask? task,
  required DateTime dueAt,
  required List<DateTime> additionalDueAts,
}) {
  if (additionalDueAts.any((date) => date.isAtSameMomentAs(dueAt))) {
    return context.tr('Choose a different future alarm time.');
  }
  final unchanged = task != null && dueAt.isAtSameMomentAs(task.dueAt);
  if (!dueAt.isAfter(DateTime.now()) && !unchanged) {
    return context.tr('Choose a future date and time.');
  }
  return null;
}

Future<bool> confirmDiscardTaskEditorChanges(
  BuildContext context, {
  required String currentSignature,
  required String initialSignature,
}) async {
  if (currentSignature == initialSignature) return true;
  return confirmTaskAction(
    context,
    title: 'Leave without saving?',
    message: context.tr('Your changes to this task will be lost.'),
    action: 'Discard changes',
  );
}

Future<void> showTaskEditor(BuildContext context, {PersonalTask? task}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksCubit>(),
        child: _buildEditor(task),
      ),
    );

Widget Function(PersonalTask?) _buildEditor = (_) => const SizedBox.shrink();
void registerTaskEditorBuilder(Widget Function(PersonalTask?) builder) {
  _buildEditor = builder;
}
