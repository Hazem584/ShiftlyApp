import 'package:get_it/get_it.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';

void registerTestCubits(GetIt locator) {
  locator
    ..registerFactory<DashboardCubit>(() => DashboardCubit(locator()))
    ..registerFactory<NotificationsCubit>(() => NotificationsCubit(locator()))
    ..registerFactory<ChatGroupsCubit>(
      () => ChatGroupsCubit(locator(), gallery: ChatImageGallery()),
    )
    ..registerFactory<ManagerTemplatesCubit>(
      () => ManagerTemplatesCubit(locator()),
    )
    ..registerFactory<WorkPatternCubit>(() => WorkPatternCubit(locator()))
    ..registerFactory<EmployeeDetailsCubit>(
      () => EmployeeDetailsCubit(locator()),
    );
}
