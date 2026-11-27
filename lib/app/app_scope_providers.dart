import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/data/native_report_file_delivery.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

Widget buildAppScopeProviders({
  required AppComposition composition,
  required Widget child,
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: composition.shiftBreaks),
      RepositoryProvider.value(value: composition.employees),
      RepositoryProvider.value(value: composition.invitations),
      RepositoryProvider.value(value: composition.workspaces),
      RepositoryProvider.value(value: composition.leaveRequests),
      RepositoryProvider.value(value: composition.profile),
      RepositoryProvider.value(value: composition.profileImagePicker),
      RepositoryProvider.value(value: composition.shifts),
      RepositoryProvider.value(value: composition.attendance),
      RepositoryProvider<ReportExporter>(
        create: (_) => AttendanceReportExporter(),
      ),
      RepositoryProvider<ReportFileDelivery>(
        create: (_) => NativeReportFileDelivery(),
      ),
      RepositoryProvider.value(value: composition.notifications),
      RepositoryProvider<ChatRepository>.value(value: composition.chat),
      RepositoryProvider<ChatRealtime>.value(value: composition.chatRealtime),
      RepositoryProvider<FixedShiftRepository>.value(
        value: composition.fixedShifts,
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        if (composition.pushNotifications != null)
          BlocProvider.value(value: composition.pushNotifications!),
        BlocProvider.value(value: composition.tasksCubit),
        BlocProvider.value(value: composition.languageCubit),
        BlocProvider.value(value: composition.themeCubit),
        BlocProvider<ReadSyncCubit>.value(value: composition.readSyncCubit),
        BlocProvider.value(value: composition.onboardingCubit),
        BlocProvider.value(value: composition.dashboardCubit),
        BlocProvider.value(value: composition.employeesCubit),
        BlocProvider.value(value: composition.workspacesCubit),
        BlocProvider.value(value: composition.leaveRequestsCubit),
        BlocProvider.value(value: composition.employeeLeaveRequestsCubit),
        BlocProvider.value(value: composition.profileCubit),
        BlocProvider.value(value: composition.managerShiftsCubit),
        BlocProvider.value(value: composition.employeeShiftsCubit),
        BlocProvider.value(value: composition.managerAttendanceCubit),
        BlocProvider.value(value: composition.attendanceCalendarCubit),
        BlocProvider.value(
          value: composition.employeeAttendanceCalendarCubit,
        ),
        BlocProvider.value(value: composition.attendanceReportsCubit),
        BlocProvider.value(value: composition.employeeAttendanceCubit),
        BlocProvider.value(value: composition.notificationsCubit),
        BlocProvider.value(value: composition.chatGroupsCubit),
        BlocProvider.value(value: composition.managerTemplatesCubit),
        BlocProvider.value(value: composition.flexibleAttendanceCubit),
      ],
      child: child,
    ),
  );
}
