import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';

class TaskEditorPageBody extends StatelessWidget {
  const TaskEditorPageBody({
    required this.step,
    required this.isNew,
    required this.saving,
    required this.error,
    required this.onNextOrSave,
    required this.stepOne,
    required this.stepTwo,
    super.key,
  });
  final int step;
  final bool isNew, saving;
  final String? error;
  final VoidCallback onNextOrSave;
  final Widget stepOne, stepTwo;

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: step == 1
          ? 'Dates and reminders'
          : isNew
          ? 'Create task'
          : 'Edit task',
      footer: FilledButton(
        key: const Key('save-personal-task'),
        onPressed: saving ? null : onNextOrSave,
        child: Text(
          context.tr(
            saving
                ? 'Saving…'
                : step == 0
                ? 'Continue to reminders'
                : 'Save task',
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Text(
              context.tr(
                step == 0
                    ? 'Step 1 of 2 · Personal to you'
                    : 'Step 2 of 2 · Device timezone',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: step,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: stepOne,
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: stepTwo,
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
