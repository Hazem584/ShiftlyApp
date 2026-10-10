import 'package:shiftly/features/auth/domain/entities/current_user.dart';

List<WorkspaceMembership> activeWorkspaceMemberships(
  List<WorkspaceMembership> memberships,
) => memberships
    .where(
      (item) =>
          item.status == MembershipStatus.active &&
          item.role != WorkspaceRole.unknown,
    )
    .toList(growable: false);
