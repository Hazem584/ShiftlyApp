import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({
    super.key,
    this.employeeRepository,
    this.dashboardRepository,
    this.leaveRequestRepository,
    this.profileRepository,
    this.profileImagePicker,
    this.router,
  });

  final EmployeeRepository? employeeRepository;
  final DashboardRepository? dashboardRepository;
  final LeaveRequestRepository? leaveRequestRepository;
  final ProfileRepository? profileRepository;
  final ProfileImagePicker? profileImagePicker;
  final GoRouter? router;

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
  late final EmployeeRepository _employees;
  late final GoRouter _router;
  late final DashboardCubit _dashboardCubit;
  late final EmployeesCubit _employeesCubit;
  late final LeaveRequestRepository _leaveRequests;
  late final ProfileRepository _profile;
  late final ProfileImagePicker _profileImagePicker;
  late final LeaveRequestsCubit _leaveRequestsCubit;
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    _employees = widget.employeeRepository ?? MockEmployeeRepository();
    final dashboard =
        widget.dashboardRepository ??
        MockDashboardRepository(employeeRepository: _employees);
    _router = widget.router ?? createAppRouter();
    _leaveRequests =
        widget.leaveRequestRepository ?? MockLeaveRequestRepository();
    _profile = widget.profileRepository ?? MockProfileRepository();
    _profileImagePicker =
        widget.profileImagePicker ?? DeviceProfileImagePicker();
    _dashboardCubit = DashboardCubit(dashboard)..load();
    _employeesCubit = EmployeesCubit(_employees)..load();
    _leaveRequestsCubit = LeaveRequestsCubit(_leaveRequests)..load();
    _profileCubit = ProfileCubit(_profile)..load();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _employeesCubit.close();
    _leaveRequestsCubit.close();
    _profileCubit.close();
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _employees),
        RepositoryProvider.value(value: _leaveRequests),
        RepositoryProvider.value(value: _profile),
        RepositoryProvider.value(value: _profileImagePicker),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _employeesCubit),
          BlocProvider.value(value: _leaveRequestsCubit),
          BlocProvider.value(value: _profileCubit),
        ],
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
