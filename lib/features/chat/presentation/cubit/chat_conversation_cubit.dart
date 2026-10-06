import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_media_validation.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';

part 'parts/chat_conversation_cubit/chat_conversation_state.dart';
part 'parts/chat_conversation_cubit/chat_upload_state.dart';
part 'parts/chat_conversation_cubit/pending_chat_media_type.dart';
part 'parts/chat_conversation_cubit/pending_chat_message.dart';
part 'parts/chat_conversation_cubit/chat_conversation_cubit.dart';

part 'parts/chat_conversation_cubit/private_media_job.dart';
part 'parts/chat_conversation_cubit/private_read_position.dart';

String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
}
