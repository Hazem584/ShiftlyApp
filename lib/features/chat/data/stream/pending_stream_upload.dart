import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

class PendingStreamUpload {
  PendingStreamUpload(
    this.scope,
    this.authorization,
    this.workspaceId,
    this.groupId,
    this.type,
    this.mime,
    this.size,
    this.duration,
    this.fileName,
  );
  final FeatureSessionScope scope;
  final ChatUploadAuthorization authorization;
  final String workspaceId, groupId, type, mime;
  final int size;
  final int? duration;
  final String? fileName;
  String? url;
}
