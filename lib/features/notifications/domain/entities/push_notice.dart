import 'package:equatable/equatable.dart';

class PushNotice extends Equatable {
  const PushNotice({
    required this.notificationId,
    required this.workspaceId,
    required this.recipientProfileId,
  });

  final String notificationId;
  final String workspaceId;
  final String recipientProfileId;

  static PushNotice? fromData(Map<String, Object?> data) {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    final notification = data['notificationId'];
    final workspace = data['workspaceId'];
    final recipient = data['recipientProfileId'];
    if (notification is! String ||
        workspace is! String ||
        recipient is! String ||
        !uuid.hasMatch(notification) ||
        !uuid.hasMatch(workspace) ||
        !uuid.hasMatch(recipient)) {
      return null;
    }
    return PushNotice(
      notificationId: notification,
      workspaceId: workspace,
      recipientProfileId: recipient,
    );
  }

  @override
  List<Object?> get props => [notificationId, workspaceId, recipientProfileId];
}
