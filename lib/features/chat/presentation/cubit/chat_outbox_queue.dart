import 'dart:async';
import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

class ChatOutboxQueue {
  // A canonical Realtime message can acknowledge a committed send before
  // its HTTP response arrives. Both paths must release the ordered lane.
  final confirmations = <String, Completer<void>>{};
  final operations = <String, ChatOutboxOperation>{};
  final localBytes = <String, Uint8List>{};
  final authorizations = <String, ChatUploadAuthorization>{};
  ChatUploadCancellation? uploadCancellation;
}
