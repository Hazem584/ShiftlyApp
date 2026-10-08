import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/manager_performance/data/memory_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/data/manager_points_page.dart';
import 'package:shiftly/features/manager_performance/data/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:shiftly/features/manager_performance/presentation/screens/employee_performance_screen.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_action_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_form_field.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_calendar.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/presentation/widgets/points_formatters.dart';

import 'points_feature_test.dart' show walletJson, dayJson;
import 'support/manager_points_fake.dart';

const scope = FeatureSessionScope(
  userId: 'manager',
  workspaceId: 'workspace',
  membershipId: 'actor',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
);

void main() {
  late ManagerPointsFake repository;
  late ManagerPerformanceCubit cubit;
  setUp(() {
    repository = ManagerPointsFake()..onGet = (_, _) async => walletJson();
    cubit = ManagerPerformanceCubit(repository, MemoryManagerIntentStorage())
      ..bindSession(scope);
  });
  tearDown(() => cubit.close());
  Widget app(Widget child, {bool scaled = false}) => BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scaled ? 2 : 1)),
          child: child,
        ),
      ),
    ),
  );

  testWidgets(
    'calendar dates, status details and legend fit compact scaled layouts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        for (final width in [280.0, 320.0]) {
          tester.view.physicalSize = Size(width, 900);
          for (final scale in [1.0, 2.0, 3.0]) {
            await tester.pumpWidget(
              app(
                Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: DefaultTextStyle(
                            style: const TextStyle(fontSize: 20, height: 1.5),
                            child: ManagerCalendar(
                              month: DateTime(2026, 10),
                              state: ManagerResourceState(
                                records: [
                                  ManagerPointsRecord(dayJson(status: 'LATE')),
                                ],
                              ),
                              timezone: scope.timezone,
                              changeMonth: (_) {},
                              cubit: cubit,
                              scope: scope,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('31'));
            await tester.pumpAndSettle();
            expect(find.text('31'), findsOneWidget);
            for (final status in PerformanceStatus.values) {
              await tester.ensureVisible(find.text(statusLabel(status)));
              await tester.pumpAndSettle();
              expect(find.text(statusLabel(status)), findsOneWidget);
            }
            expect(
              tester.takeException(),
              isNull,
              reason: 'width=$width, text scale=$scale',
            );
            await tester.ensureVisible(find.text('7'));
            await tester.pumpAndSettle();
            expect(
              find.bySemanticsLabel(RegExp('2026-10-07, Late')),
              findsOneWidget,
            );
            await tester.tap(find.text('7'));
            await tester.pumpAndSettle();
            expect(find.text('2026-10-07'), findsOneWidget);
            expect(find.text('Evening'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('Close'));
            await tester.pumpAndSettle();
          }
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'employee target identity, compact scaled controls and no manager redemption',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          const EmployeePerformanceScreen(membershipId: 'membership-a'),
          scaled: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        repository.calls.every((call) => call['target'] == 'membership-a'),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Adjust points'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Adjust points'), findsOneWidget);
      expect(find.text('Grant BLUE'), findsOneWidget);
      expect(find.text('Redeem'), findsNothing);
      expect(find.textContaining('GOLD adjustment'), findsNothing);
      expect(tester.takeException(), isNull);
      cubit.bindSession(null);
      await tester.pumpAndSettle();
      expect(find.text('Adjust points'), findsNothing);
      expect(find.text('Membership: membership-a'), findsNothing);
    },
  );
  testWidgets('employee selection never flashes previous private records', (
    tester,
  ) async {
    repository.onList = (resource, target, _) async => resource == 'calendar'
        ? const ManagerPointsPage([])
        : ManagerPointsPage([
            ManagerPointsRecord({
              'id': target!,
              'reason': 'Private $target',
              'explanation': 'Employee evidence',
            }),
          ]);
    await tester.pumpWidget(
      app(const EmployeePerformanceScreen(membershipId: 'a')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Extra effort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extra effort'));
    await tester.pumpAndSettle();
    expect(find.text('Private a'), findsOneWidget);
    await tester.pumpWidget(
      app(const EmployeePerformanceScreen(membershipId: 'b')),
    );
    await tester.pump();
    expect(find.text('Private a'), findsNothing);
    await tester.pumpAndSettle();
    expect(repository.calls.last['target'], 'b');
  });
  testWidgets(
    'dialog owns controllers and hides sensitive input after scope loss',
    (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ManagerActionDialog(
                    title: 'Adjust points',
                    fields: ManagerForms.adjustment(),
                    cubit: cubit,
                    scope: scope,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final explanation = find.widgetWithText(TextFormField, 'Explanation');
      await tester.enterText(explanation, 'Private explanation');
      cubit.bindSession(null);
      await tester.pumpAndSettle();
      expect(find.text('Private explanation'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('policy date is real, future and later than version history', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ManagerActionDialog(
            title: 'New policy',
            fields: const [
              ManagerFormField('effectiveFrom', 'Effective date', date: true),
            ],
            afterDate: '2099-10-10',
            cubit: cubit,
            scope: scope,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2099-02-31');
    await tester.tap(find.text('Review change'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a real calendar date.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2099-10-09');
    await tester.tap(find.text('Review change'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a future date after the latest version.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '2099-10-11');
    await tester.tap(find.text('Review change'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm new policy?'), findsOneWidget);
    cubit.bindSession(null);
    await tester.pumpAndSettle();
    expect(find.textContaining('2099-10-11'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
