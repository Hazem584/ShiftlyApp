import 'package:get_it/get_it.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_connection.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_realtime.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/domain/services/chat_outbox_coordinator.dart';
import 'package:shiftly/features/notifications/data/api_notification_repository.dart';
import 'package:shiftly/features/notifications/data/api_push_device_repository.dart';
import 'package:shiftly/features/notifications/data/firebase_push_messaging.dart';
import 'package:shiftly/features/notifications/data/preferences_push_store.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';

void registerCollaborationProductionDependencies(GetIt t) {
  t
    ..registerLazySingleton<ChatMessageCache>(() => ChatMessageCache(t()))
    ..registerLazySingleton<ChatOutboxCoordinator>(ChatOutboxCoordinator.new)
    ..registerLazySingleton<ChatOutboxStorage>(
      () => ChatOutboxStorage(t(), coordinator: t()),
    )
    ..registerLazySingleton<ChatMediaCache>(
      () => ChatMediaCache(t()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton<NotificationRepository>(
      () => ApiNotificationRepository(t()),
    )
    ..registerLazySingleton<PushDeviceRepository>(
      () => ApiPushDeviceRepository(t()),
    )
    ..registerLazySingleton<PushMessaging>(FirebasePushMessaging.new)
    ..registerLazySingleton<PushPreferenceStore>(() => PreferencesPushStore(t()))
    ..registerLazySingleton<SupabaseChatStorageUploader>(
      () => SupabaseChatStorageUploader(t()),
    )
    ..registerLazySingleton<StreamChatConnection>(
      () => StreamChatConnection(t()),
      dispose: (c) => c.dispose(),
    )
    ..registerLazySingleton<ChatRepository>(
      () => StreamChatRepository(
        ApiChatRepository(
          t(),
          storageUploader: t<SupabaseChatStorageUploader>(),
        ),
        t<StreamChatConnection>(),
      ),
    )
    ..registerLazySingleton<ChatRealtime>(
      () => StreamChatRealtime(
        t<StreamChatConnection>(),
        SupabaseChatRealtime(t()),
      ),
    );
}
