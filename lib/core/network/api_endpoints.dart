abstract final class ApiEndpoints {
  static const bootstrap = '/auth/bootstrap';
  static const currentUser = '/auth/me';
  static const profile = '/profiles/me';
  static const avatar = '/profiles/me/avatar';
  static const workspaces = '/workspaces';
  static String workspace(String workspaceId) => '/workspaces/$workspaceId';
  static String employees(String workspaceId) =>
      '/workspaces/$workspaceId/employees';
  static String employee(String workspaceId, String membershipId) =>
      '/workspaces/$workspaceId/employees/$membershipId';
  static String workspaceInvitations(String workspaceId) =>
      '/workspaces/$workspaceId/invitations';
  static const myInvitations = '/invitations/me';
  static const acceptInvitation = '/invitations/accept';
}
