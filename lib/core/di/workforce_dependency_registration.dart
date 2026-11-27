import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/api_attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/data/api_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/employees/data/api_workforce_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:shiftly/features/shifts/data/api_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/support/data/api_support_repository.dart';
import 'package:shiftly/features/support/domain/support_repository.dart';
import 'package:shiftly/features/tasks/data/api_task_repository.dart';
import 'package:shiftly/features/tasks/data/device_task_reminders.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';
import 'package:shiftly/features/tasks/domain/task_repository.dart';
import 'package:shiftly/features/team_work/data/api_team_work_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

void registerWorkforceProductionDependencies(GetIt t) {
  t
    ..registerLazySingleton<SupportRepository>(() => ApiSupportRepository(t()))
    ..registerLazySingleton<AttendanceControlsRepository>(
      () => ApiAttendanceControlsRepository(t()),
    )
    ..registerLazySingleton<TaskRepository>(() => ApiTaskRepository(t()))
    ..registerLazySingleton<TaskReminders>(
      () => DeviceTaskReminders(
        t<SharedPreferences>(),
        t<PushPreferenceStore>(),
      ),
    )
    ..registerLazySingleton<TeamWorkRepository>(() => ApiTeamWorkRepository(t()))
    ..registerLazySingleton<ApiWorkforceRepository>(() => ApiWorkforceRepository(t()))
    ..registerLazySingleton<EmployeeRepository>(() => t<ApiWorkforceRepository>())
    ..registerLazySingleton<InvitationRepository>(() => t<ApiWorkforceRepository>())
    ..registerLazySingleton<WorkspaceRepository>(() => t<ApiWorkforceRepository>())
    ..registerLazySingleton<ShiftRepository>(() => ApiShiftRepository(t()))
    ..registerLazySingleton<AttendanceRepository>(() => ApiAttendanceRepository(t()))
    ..registerLazySingleton<LeaveRequestRepository>(() => ApiLeaveRequestRepository(t()))
    ..registerLazySingleton<AttendanceCalendarRepository>(
      () => ApiAttendanceCalendarRepository(t(), t(), t(), dio: t<Dio>()),
    );
}
