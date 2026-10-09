import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart';

import 'support/attendance_test_cubit.dart';

void main() {
  testWidgets('notice fits a narrow RTL screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: FailureNotice(
                  failure: const Failure(
                    message: 'Refresh to confirm the latest attendance before starting another shift.',
                    requestId: 'request-12345',
                  ),
                  onRefresh: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'support reference is selectable and refresh is disabled while pending',
    (tester) async {
      var calls = 0;
      Widget app(bool refreshing) => MaterialApp(
        home: Scaffold(
          body: FailureNotice(
            failure: const Failure(
              message: 'Check your connection.',
              kind: FailureKind.network,
              requestId: 'request-42',
            ),
            refreshing: refreshing,
            onRefresh: () => calls++,
          ),
        ),
      );
      await tester.pumpWidget(app(false));
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.tap(find.text('Refresh status'));
      expect(calls, 1);
      await tester.pumpWidget(app(true));
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'active attendance keeps refresh failures visible and refreshes without resubmitting',
    (tester) async {
      final date = DateTime.utc(2030, 1, 1, 9);
      final cubit = AttendanceTestCubit(
        FlexibleAttendanceState(
          loading: false,
          failure: const Failure(
            message: 'Connection unavailable',
            kind: FailureKind.network,
          ),
          current: FlexibleAttendance(
            id: 'attendance',
            workspaceId: 'workspace',
            employeeMembershipId: 'member',
            source: AttendanceSource.template,
            classification: AttendanceClassification.onTime,
            clockInAt: date,
            minutesLate: 0,
            createdAt: date,
            updatedAt: date,
          ),
        ),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<FlexibleAttendanceCubit>.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FlexibleAttendancePanel(timezone: 'Etc/UTC'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('failure-notice')), findsOneWidget);
      expect(find.text('You are clocked in'), findsOneWidget);
      await tester.tap(find.text('Refresh status'));
      expect(cubit.refreshes, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
