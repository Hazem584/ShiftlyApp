import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app/app_dependencies.dart';
import 'package:shiftly/app/app_providers_state.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class AppProviders extends StatefulWidget {
  const AppProviders({
    super.key,
    this.locator,
    this.onboardingStorage,
    this.preview = false,
    this.employeeRepository,
    this.invitationRepository,
    this.workspaceRepository,
    this.dashboardRepository,
    this.leaveRequestRepository,
    this.profileRepository,
    this.profileImagePicker,
    this.router,
    this.sessionCoordinator,
    this.shiftRepository,
    this.attendanceRepository,
    this.notificationRepository,
    this.chatRepository,
    this.chatRealtime,
    this.fixedShiftRepository,
    this.languageStore,
  });

  final GetIt? locator;
  final OnboardingStorage? onboardingStorage;
  final bool preview;
  final EmployeeRepository? employeeRepository;
  final InvitationRepository? invitationRepository;
  final WorkspaceRepository? workspaceRepository;
  final DashboardRepository? dashboardRepository;
  final LeaveRequestRepository? leaveRequestRepository;
  final ProfileRepository? profileRepository;
  final ProfileImagePicker? profileImagePicker;
  final GoRouter? router;
  final SessionCoordinator? sessionCoordinator;
  final ShiftRepository? shiftRepository;
  final AttendanceRepository? attendanceRepository;
  final NotificationRepository? notificationRepository;
  final ChatRepository? chatRepository;
  final ChatRealtime? chatRealtime;
  final FixedShiftRepository? fixedShiftRepository;
  final LanguagePreferenceStore? languageStore;

  AppDependencies get dependencies => AppDependencies(
    locator: locator,
    onboardingStorage: onboardingStorage,
    preview: preview,
    employeeRepository: employeeRepository,
    invitationRepository: invitationRepository,
    workspaceRepository: workspaceRepository,
    dashboardRepository: dashboardRepository,
    leaveRequestRepository: leaveRequestRepository,
    profileRepository: profileRepository,
    profileImagePicker: profileImagePicker,
    router: router,
    sessionCoordinator: sessionCoordinator,
    shiftRepository: shiftRepository,
    attendanceRepository: attendanceRepository,
    notificationRepository: notificationRepository,
    chatRepository: chatRepository,
    chatRealtime: chatRealtime,
    fixedShiftRepository: fixedShiftRepository,
    languageStore: languageStore,
  );

  @override
  State<AppProviders> createState() => AppProvidersState();
}
