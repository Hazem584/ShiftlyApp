import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/employee_leave_requests_panel.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

const _scope = FeatureSessionScope(
  userId: 'employee',
  workspaceId: 'workspace-id',
  membershipId: 'employee-id',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.employee,
);

LeaveRequestRecord _record(
  String id,
  LeaveRequestStatus status, {
  String? rejectionReason,
}) => LeaveRequestRecord(
  id: id,
  workspaceId: 'workspace-id',
  employeeMembershipId: 'employee-id',
  type: LeaveRequestType.annualLeave,
  status: status,
  startsAt: DateTime.utc(2030, 1, 1),
  endsAt: DateTime.utc(2030, 1, 1, 23, 59),
  reason: 'Family event',
  rejectionReason: rejectionReason,
  createdAt: DateTime.utc(2029, 12, 1),
  updatedAt: DateTime.utc(2029, 12, 1),
  employee: const ShiftEmployeeSummary(
    membershipId: 'employee-id',
    profileId: 'profile-id',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
    fullName: 'Mariam Hassan',
  ),
);

class _Repository implements LeaveRequestRepository {
  final records = <LeaveRequestRecord>[
    _record('pending', LeaveRequestStatus.pending),
    _record('approved', LeaveRequestStatus.approved),
    _record(
      'rejected',
      LeaveRequestStatus.rejected,
      rejectionReason: 'No coverage',
    ),
    _record('cancelled', LeaveRequestStatus.cancelled),
  ];
  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) async => LeaveRequestPage(
    data: List.of(records),
    pagination: const ApiPagination(
      page: 1,
      limit: 20,
      total: 4,
      totalPages: 1,
    ),
  );
  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) async {
    final index = records.indexWhere((item) => item.id == requestId);
    final current = records[index];
    final cancelled = _record(current.id, LeaveRequestStatus.cancelled);
    records[index] = cancelled;
    return cancelled;
  }

  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) async => _record('created', LeaveRequestStatus.pending);
  @override
  Future<LeaveRequestRecord> getMine(String requestId) async =>
      records.firstWhere((item) => item.id == requestId);
  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) async => throw UnimplementedError();
  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) async => throw UnimplementedError();
  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) async => throw UnimplementedError();
}

void main() {
  testWidgets(
    'employee leave panel renders all statuses, reason, and cancellation confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final cubit = EmployeeLeaveRequestsCubit(_Repository())
        ..bindSession(_scope);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const EmployeeLeaveRequestsPanel(timezone: 'Etc/UTC'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Rejection reason: No coverage'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('cancel-pending')));
      await tester.tap(find.byKey(const Key('cancel-pending')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel leave request?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cancel-leave')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cancel-pending')), findsNothing);
      ToastService.dismissAll();
    },
  );

  testWidgets(
    'request form validates a missing reason and prevents submission',
    (tester) async {
      final cubit = EmployeeLeaveRequestsCubit(_Repository())
        ..bindSession(_scope);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const EmployeeLeaveRequestsPanel(timezone: 'Etc/UTC'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request-leave')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('submit-leave-request')));
      await tester.pump();
      expect(find.text('A reason is required'), findsOneWidget);
      expect(find.text('Request leave'), findsWidgets);
    },
  );
}
