import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';

class EmployeePendingInvitations extends StatelessWidget {
  const EmployeePendingInvitations({super.key, required this.invitations});
  final List<WorkspaceInvitation> invitations;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('pending-invitations'),
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      context.tr('{value1} pending invitation{value2}', {
        'value1': (invitations.length).toString(),
        'value2': (invitations.length == 1 ? '' : 's').toString(),
      }),
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
