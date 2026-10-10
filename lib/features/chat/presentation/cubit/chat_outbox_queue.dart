import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

class ChatOutboxQueue {
  final operations = <String, ChatOutboxOperation>{};
  final localBytes = <String, Uint8List>{};
  final authorizations = <String, ChatUploadAuthorization>{};
  ChatUploadCancellation? uploadCancellation;
}
