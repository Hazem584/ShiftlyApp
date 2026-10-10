import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/arabic_translations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_status_card.dart';

void main() {
  testWidgets(
    'Arabic manager navigation and profile remain usable on a compact screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final employees = MockEmployeeRepository(delay: Duration.zero);
      await tester.pumpWidget(
        ShiftlyApp.preview(
          languageStore: MemoryLanguageStore('ar'),
          employeeRepository: employees,
          dashboardRepository: MockDashboardRepository(
            employeeRepository: employees,
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('إجمالي الموظفين'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-4')));
      await tester.pumpAndSettle();
      expect(find.text('الملف الشخصي للمدير'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('language-selector')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('profile-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const Key('language-selector')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'changing language updates direction and labels without resetting current route',
    (tester) async {
      final store = MemoryLanguageStore('en');
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const _LanguageProbe()),
          GoRoute(path: '/settings', builder: (_, _) => const _LanguageProbe()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ShiftlyApp.preview(router: router, languageStore: store),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.tap(find.byKey(const Key('language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('العربية'),
          matching: find.byType(CheckedPopupMenuItem<AppLanguage>),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.languageCode, 'ar');
      expect(find.text('الرئيسية'), findsOneWidget);
      final context = tester.element(find.byKey(const Key('localized-probe')));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(Localizations.localeOf(context).languageCode, 'ar');
      expect(router.routeInformationProvider.value.uri.path, '/settings');
      await tester.tap(find.byKey(const Key('language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('English'),
          matching: find.byType(CheckedPopupMenuItem<AppLanguage>),
        ),
      );
      await tester.pumpAndSettle();
      expect(Directionality.of(context), TextDirection.ltr);
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'device Arabic is selected automatically and unsupported languages use English',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = const [
        Locale('ar', 'EG'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const _LanguageProbe())],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ShiftlyApp.preview(router: router));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('الرئيسية'), findsOneWidget);
      tester.binding.platformDispatcher.localesTestValue = const [Locale('fr')];
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Arabic attendance and failure messages fit compact enlarged layout',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const AttendanceStatusCard(
                      state: FlexibleAttendanceState(loading: false),
                      timezone: 'Africa/Cairo',
                    ),
                    FailureNotice(
                      failure: const Failure(
                        message: 'We could not read the latest information. Refresh to load it again.',
                        requestId: 'request-123',
                        kind: FailureKind.network,
                      ),
                      onRefresh: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('حالة حضورك تحتاج إلى مراجعة'), findsOneWidget);
      expect(find.text('تحديث الحالة'), findsOneWidget);
      expect(find.textContaining('request-123'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('translation preserves parameter content and every message has matching placeholders', () {
    const ar = AppLocalizations(Locale('ar'));
    expect(
      ar.text('Choose {name} {location} to start your attendance.', {
        'name': 'Morning {location}',
        'location': 'بالأسفل',
      }),
      'اختر Morning {location} بالأسفل لتسجيل حضورك.',
    );
    expect(ar.text('Hello, {name}', {'name': 'Dashboard'}), 'أهلًا، Dashboard');
    for (final entry in arabicTranslations.entries) {
      Set<String> placeholders(String value) =>
          RegExp(r'\{\w+\}').allMatches(value).map((m) => m.group(0)!).toSet();
      expect(
        placeholders(entry.value),
        placeholders(entry.key),
        reason: entry.key,
      );
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
  });
}

class _LanguageProbe extends StatelessWidget {
  const _LanguageProbe();
  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('localized-probe'),
    appBar: AppBar(actions: const [LanguageSelector()]),
    body: Text(context.tr('Dashboard')),
  );
}
