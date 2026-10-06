part of '../../employees_screen.dart';

class _PendingInvitations extends StatelessWidget {
  const _PendingInvitations({required this.invitations});
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
      '${invitations.length} pending invitation${invitations.length == 1 ? '' : 's'}',
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
