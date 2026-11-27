import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shiftly/core/di/collaboration_dependency_registration.dart';
import 'package:shiftly/core/di/operations_dependency_registration.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'production chat factory resolves the registered storage instances',
    () async {
      final locator = GetIt.asNewInstance();
      final directory = await Directory.systemTemp.createTemp(
        'shiftly-chat-di-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final database = await ChatCacheDatabase.open(
        ChatStorageDirectory(directory.path),
      );
      locator
        ..registerSingleton(database, dispose: (value) => value.close())
        ..registerSingleton(Dio(), dispose: (value) => value.close(force: true))
        ..registerSingleton(
          SupabaseClient('https://shiftly-smoke.invalid', 'fixture-key'),
          dispose: (value) => value.dispose(),
        );
      addTearDown(locator.reset);
      registerCollaborationProductionDependencies(locator);
      registerOperationsAndFactoryDependencies(locator);

      final cubit = locator<ChatGroupsCubit>();
      addTearDown(cubit.close);
      expect(cubit.messageCache, same(locator<ChatMessageCache>()));
      expect(cubit.mediaCache, same(locator<ChatMediaCache>()));
      expect(cubit.outbox, same(locator<ChatOutboxStorage>()));
    },
  );
}
