import 'package:get_it/get_it.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_group_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/data/cache/chat_message_cache.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/features/chat/data/outbox/chat_outbox_storage.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/data/api_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/api_schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/profile/data/api_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';

void registerOperationsAndFactoryDependencies(GetIt t) {
  t
    ..registerLazySingleton<DashboardRepository>(
      () => ApiDashboardRepository(t()),
    )
    ..registerLazySingleton<FixedShiftRepository>(
      () => ApiFixedShiftRepository(t(), t()),
    )
    ..registerLazySingleton<ExtraShiftRepository>(
      () => t<FixedShiftRepository>() as ExtraShiftRepository,
    )
    ..registerLazySingleton<ScheduleExceptionRepository>(
      () => ApiScheduleExceptionRepository(t()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ApiProfileRepository(
        t(),
        () => t<SessionCoordinator>().state.activeMembership,
        currentUser: () => t<SessionCoordinator>().state.currentUser,
      ),
    )
    ..registerLazySingleton<ProfileImagePicker>(DeviceProfileImagePicker.new)
    ..registerFactory<DashboardCubit>(() => DashboardCubit(t()))
    ..registerFactory<NotificationsCubit>(() => NotificationsCubit(t()))
    ..registerFactory<ChatGroupsCubit>(
      () => ChatGroupsCubit(
        t(),
        messageCache: t<ChatMessageCache>(),
        realtime: t(),
        groupCache: ChatGroupCache(t<ChatCacheDatabase>()),
        outbox: t<ChatOutboxStorage>(),
        mediaCache: t<ChatMediaCache>(),
        gallery: ChatImageGallery(),
      ),
    )
    ..registerFactory<ManagerTemplatesCubit>(() => ManagerTemplatesCubit(t()))
    ..registerFactory<WorkPatternCubit>(() => WorkPatternCubit(t()))
    ..registerFactory<EmployeeDetailsCubit>(() => EmployeeDetailsCubit(t()));
}
