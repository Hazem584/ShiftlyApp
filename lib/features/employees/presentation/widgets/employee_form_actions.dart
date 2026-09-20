import 'package:flutter/material.dart';

class EmployeeFormActions extends StatelessWidget {
  const EmployeeFormActions({
    super.key,
    required this.submitting,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool submitting;
  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: submitting ? null : onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            key: const Key('submit-employee'),
            onPressed: canSubmit && !submitting ? onSubmit : null,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1_rounded, size: 19),
            label: Text(submitting ? 'Adding employee…' : 'Add Employee'),
          ),
        ),
      ],
    ),
  );
}
