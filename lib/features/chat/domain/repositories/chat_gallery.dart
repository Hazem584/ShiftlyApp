import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';

abstract interface class ChatGallery {
  Future<void> save({
    required ChatMessage message,
    required ChatRepository repository,
    required FeatureSessionScope session,
    required bool Function() hasAccess,
    ChatMediaStore? cache,
  });
}
