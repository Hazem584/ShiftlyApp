import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/app/app_composition_state.dart';
import 'package:shiftly/app/app_task_coordinator.dart';
import 'package:shiftly/app/workspace_local_cleanup.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/breaks/data/api_shift_break.dart';
import 'package:shiftly/features/breaks/domain/break_notifier.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/data/native_task_home_widget.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';
import 'package:shiftly/features/tasks/domain/task_repository.dart';

void initializeCollaborationAndTasksComposition(
  AppCompositionState c,
  T? Function<T extends Object>() registered,
) {
  final locator = c.dependencies.locator;
  if (locator?.isRegistered<PushMessaging>() == true) {
    c.pushDevices = locator!<PushDeviceRepository>();
    c.pushNotifications = PushNotificationsCubit(
      locator<PushMessaging>(),
      c.pushDevices!,
      locator<PushPreferenceStore>(),
      onOpened: (notice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (c.isMounted()) unawaited(c.onOpened(notice));
        });
        WidgetsBinding.instance.scheduleFrame();
      },
      onForeground: c.onForeground,
    );
  }
  c.chat =
      c.dependencies.chatRepository ??
      registered<ChatRepository>() ??
      const MockChatRepository();
  c.chatRealtime =
      c.dependencies.chatRealtime ??
      registered<ChatRealtime>() ??
      const NoopChatRealtime();
  c.chatGroupsCubit =
      registered<ChatGroupsCubit>() ??
      ChatGroupsCubit(
        c.chat,
        gallery: ChatImageGallery(),
        realtime: c.chatRealtime,
      );
  final localReminders = registered<TaskReminders>();
  final dio = registered<Dio>();
  c.shiftBreaks = ShiftBreakController(
    changeRemote: dio == null ? null : ApiShiftBreak(dio).change,
    preferences: registered<SharedPreferences>(),
    notifier: localReminders is BreakNotifier
        ? localReminders as BreakNotifier
        : null,
  );
  c.workspaceRemoval = WorkspaceLocalCleanup(
    session: c.sessionCoordinator,
    breaks: c.shiftBreaks,
    reads: c.readSyncCubit.store,
    chat: registered<ChatCacheDatabase>(),
  );
  c.breakAttendanceSubscription = c.flexibleAttendanceCubit.stream.listen((s) {
    final closed = s.current;
    if (closed?.isOpen == true) {
      c.shiftBreaks.restore(
        closed!.id,
        policy: closed.breakState,
        arabic: c.languageCubit.state.languageCode == 'ar',
      );
    }
    if (closed?.clockOutAt != null) {
      unawaited(c.shiftBreaks.finishFor(closed!.id));
    }
  });
  c.tasksCubit = TasksCubit(
    registered<TaskRepository>() ?? MemoryTaskRepository(),
    localReminders ?? const NoTaskReminders(),
    enableRemoteReminders: () async => c.pushNotifications?.setEnabled(true),
    homeWidget: NativeTaskHomeWidget.supported ? NativeTaskHomeWidget() : null,
  );
  c.taskCoordinator = AppTaskCoordinator(
    c.tasksCubit,
    c.router,
    c.isMounted,
    c.onOpened,
  );
}
