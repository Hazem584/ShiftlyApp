import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/employees/data/api_workforce_base.dart';
import 'package:shiftly/features/employees/data/workforce_entity_mapper.dart';
import 'package:shiftly/features/employees/data/workforce_json_parser.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

mixin ApiInvitationMixin on ApiWorkforceBase implements InvitationRepository {
  @override
  Future<WorkspaceInvitation> createInvitation({
    required String workspaceId,
    required String email,
    String? jobTitle,
  }) => request(() async {
    final normalizedTitle = jobTitle?.trim();
    final res = await dio.post<Object?>(
      ApiEndpoints.workspaceInvitations(workspaceId),
      data: <String, Object?>{
        'email': email.trim().toLowerCase(),
        if (normalizedTitle?.isNotEmpty == true) 'jobTitle': normalizedTitle,
      },
    );
    return parseManagerInvitation(asJsonMap(res.data));
  });

  @override
  Future<List<WorkspaceInvitation>> listWorkspaceInvitations({
    required String workspaceId,
    InvitationStatus? status,
  }) => request(() async {
    final res = await dio.get<Object?>(
      ApiEndpoints.workspaceInvitations(workspaceId),
      queryParameters: <String, Object?>{
        if (status != null && status != InvitationStatus.unknown)
          'status': invitationStatusValue(status),
      },
    );
    return asJsonList(res.data)
        .map((item) => parseManagerInvitation(asJsonMap(item)))
        .toList(growable: false);
  });

  @override
  Future<List<WorkspaceInvitation>> listMyInvitations() => request(() async {
    final res = await dio.get<Object?>(ApiEndpoints.myInvitations);
    return asJsonList(res.data)
        .map((item) => _parseMyInvitation(asJsonMap(item)))
        .toList(growable: false);
  });

  @override
  Future<WorkspaceRecord> acceptInvitation(String inviteToken) => request(
    () async => parseAcceptedWorkspace(
      (await dio.post<Object?>(
        ApiEndpoints.acceptInvitation,
        data: <String, Object?>{'inviteToken': inviteToken.trim()},
      )).data,
    ),
  );

  @override
  Future<WorkspaceRecord> acceptInvitationById(String id) => request(
    () async => parseAcceptedWorkspace(
      (await dio.post<Object?>(
        '/invitations/${Uri.encodeComponent(id)}/accept',
      )).data,
    ),
  );

  @override
  Future<void> declineInvitation(String id) => request(() async {
    await dio.post<Object?>('/invitations/${Uri.encodeComponent(id)}/decline');
  });

  WorkspaceInvitation _parseMyInvitation(Map<String, Object?> json) {
    final ws = parseWorkspaceRecord({
      ...asJsonMap(json['workspace']),
      'role': 'EMPLOYEE',
      'status': 'INVITED',
    });
    return WorkspaceInvitation(
      id: readString(json, 'id'),
      workspaceId: ws.id,
      jobTitle: optionalString(json['jobTitle']),
      role: parseWorkspaceRole(json['role']),
      status: InvitationStatus.pending,
      expiresAt: requiredDate(json, 'expiresAt'),
      workspace: ws,
    );
  }
}
