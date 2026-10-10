import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/arabic_translations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/manager_performance/data/memory_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/screens/employee_performance_screen.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_action_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_operation_formatters.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_display_text.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/presentation/widgets/points_achievements.dart';
import 'package:shiftly/features/points/presentation/widgets/points_wallet.dart';

import 'points_feature_test.dart' show walletJson;
import 'support/manager_points_fake.dart';

const _scope = FeatureSessionScope(
  userId: 'manager',
  workspaceId: 'workspace',
  membershipId: 'actor',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
);

Widget _arabicApp(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets(
    'Arabic system notifications preserve names and unknown content',
    (tester) async {
      await tester.pumpWidget(
        _arabicApp(
          Builder(
            builder: (context) => Column(
              children: [
                Text(
                  managerOperationDetails(context, const {
                    'reason': 'COVERED_EMPLOYEE',
                  }, resource: 'extra-effort/award-id/reverse'),
                ),
                Text(
                  notificationDisplayMessage(
                    context,
                    NotificationType.attendanceClockedIn,
                    'Dashboard has clocked in.',
                  ),
                ),
                Text(
                  notificationDisplayMessage(
                    context,
                    NotificationType.leaveRequestCreated,
                    'Basel {name} submitted a leave request.',
                  ),
                ),
                Text(
                  notificationDisplayMessage(
                    context,
                    NotificationType.unknown,
                    'Custom untouched content',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('سجّل Dashboard الحضور.'), findsOneWidget);
      expect(find.text('قدّم Basel {name} طلب إجازة.'), findsOneWidget);
      expect(find.text('Custom untouched content'), findsOneWidget);
      expect(find.textContaining('COVERED_EMPLOYEE'), findsOneWidget);
    },
  );
  testWidgets(
    'Arabic points balances and empty achievements fit enlarged mobile layout',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _arabicApp(
          Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    PointsWalletView(
                      wallet: PointsWallet.fromJson(walletJson()),
                    ),
                    const PointsAchievements(
                      items: [],
                      timezone: 'Africa/Cairo',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('رصيد النقاط'), findsOneWidget);
      expect(find.text('النقاط الخضراء المتاحة'), findsOneWidget);
      expect(find.text('النقاط الحمراء النشطة'), findsOneWidget);
      expect(find.text('ستظهر شاراتك الذهبية النشطة هنا.'), findsOneWidget);
      expect(find.text('GREEN available'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'employee points screen translates controls and keeps target identity',
    (tester) async {
      final repository = ManagerPointsFake()
        ..onGet = (_, _) async => walletJson();
      final cubit = ManagerPerformanceCubit(
        repository,
        MemoryManagerIntentStorage(),
      )..bindSession(_scope);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: _arabicApp(
            const EmployeePerformanceScreen(
              membershipId: 'employee-original-id',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('أداء الموظف'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('تعديل النقاط'), 200);
      expect(find.text('منح نقاط زرقاء'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('المجهود الإضافي'), 150);
      expect(find.text('المجهود الإضافي'), findsOneWidget);
      expect(
        repository.calls.every(
          (call) => call['target'] == 'employee-original-id',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic grant form and confirmation preserve API enums and free text',
    (tester) async {
      final cubit = ManagerPerformanceCubit(
        ManagerPointsFake(),
        MemoryManagerIntentStorage(),
      )..bindSession(_scope);
      addTearDown(cubit.close);
      Map<String, Object?>? payload;
      await tester.pumpWidget(
        _arabicApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  payload = await showDialog<Map<String, Object?>>(
                    context: context,
                    builder: (_) => ManagerActionDialog(
                      title: 'Grant extra effort',
                      fields: ManagerForms.effort(),
                      cubit: cubit,
                      scope: _scope,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('مكافأة مجهود إضافي'), findsOneWidget);
      expect(find.text('تغطية شيفت موظف آخر'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Original employee evidence',
      );
      await tester.tap(find.text('مراجعة التغيير'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد مكافأة مجهود إضافي؟'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('Original employee evidence') ?? false),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(payload?['reason'], 'COVERED_EMPLOYEE');
      expect(payload?['bluePoints'], 1);
      expect(payload?['explanation'], 'Original employee evidence');
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'every mapped API error and points form label has an Arabic translation',
    () {
      final source = File('lib/core/error/api_error_parser.dart')
          .readAsStringSync();
      for (final match in RegExp(r"=>\s*'([^']+)'").allMatches(source)) {
        final message = match[1]!;
        expect(
          arabicTranslations.containsKey(message),
          isTrue,
          reason: message,
        );
      }
      for (final field in [
        ...ManagerForms.policy,
        ...ManagerForms.adjustment(),
        ...ManagerForms.adjustment(reverse: true),
        ...ManagerForms.effort(),
        ...ManagerForms.effort(reverse: true),
        ...ManagerForms.review,
      ]) {
        expect(
          arabicTranslations.containsKey(field.label),
          isTrue,
          reason: field.label,
        );
        if (field.help != null) {
          expect(
            arabicTranslations.containsKey(field.help),
            isTrue,
            reason: field.help,
          );
        }
        for (final choice in field.choices ?? <String>[]) {
          expect(
            arabicTranslations.containsKey(choice),
            isTrue,
            reason: choice,
          );
        }
      }
    },
  );
}
