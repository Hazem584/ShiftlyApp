import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/fixed_shifts/data/api_schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/schedule_exception_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/day_exception_notices.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

import 'support/report_fixtures.dart';

Map<String, Object?> recordJson({String workspaceId = 'workspace'}) => {
  'id': 'exception',
  'workspaceId': workspaceId,
  'employeeMembershipId': null,
  'operationalDate': '2026-10-20',
  'kind': 'HOLIDAY',
  'status': 'ACTIVE',
  'reason': 'Public holiday',
  'createdByMembershipId': 'manager',
  'createdAt': '2026-10-12T12:00:00Z',
  'creatorName': 'Sam',
};

class _Repository implements ScheduleExceptionRepository {
  final ids = <String>[];
  bool fail = false;
  String? kind;
  final pages = <int>[];
  @override
  Future<ScheduleExceptionPage> list(
    String workspaceId, {
    String? employeeMembershipId,
    int page = 1,
  }) async {
    pages.add(page);
    return ScheduleExceptionPage([
      ScheduleException.fromJson({...recordJson(), 'id': 'exception-$page'}),
    ], ApiPagination(page: page, limit: 20, total: 21, totalPages: 2));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<ScheduleException> create(
    String workspaceId, {
    required String clientExceptionId,
    required String kind,
    required String operationalDate,
    required String reason,
    String? employeeMembershipId,
    String? shiftTemplateId,
  }) async {
    ids.add(clientExceptionId);
    this.kind = kind;
    if (fail) throw const ApiException(message: 'Try again');
    expect(employeeMembershipId, isNull);
    expect(shiftTemplateId, isNull);
    return ScheduleException.fromJson(recordJson());
  }
}

class _FixedRepository implements FixedShiftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(Widget child, {bool arabic = false}) => MaterialApp(
  locale: Locale(arabic ? 'ar' : 'en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  test('API sends holiday fields without an employee or template and rejects foreign workspace data', () async {
    final dio = Dio();
    RequestOptions? captured;
    var foreign = false;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: recordJson(workspaceId: foreign ? 'other' : 'workspace'),
            ),
          );
        },
      ),
    );
    final repository = ApiScheduleExceptionRepository(dio);
    await repository.create(
      'workspace',
      clientExceptionId: 'client',
      kind: 'HOLIDAY',
      operationalDate: '2026-10-20',
      reason: 'Public holiday',
    );
    expect(captured!.path, '/workspaces/workspace/schedule-exceptions');
    expect(captured!.data, {
      'clientExceptionId': 'client',
      'kind': 'HOLIDAY',
      'operationalDate': '2026-10-20',
      'reason': 'Public holiday',
    });
    foreign = true;
    await expectLater(
      repository.create(
        'workspace',
        clientExceptionId: 'client',
        kind: 'HOLIDAY',
        operationalDate: '2026-10-20',
        reason: 'Public holiday',
      ),
      throwsA(isA<ApiException>()),
    );
    dio.close();
  });
  test('audit parses the saved schedule, creator and cancellation', () {
    final record = ScheduleException.fromJson({
      ...recordJson(),
      'kind': 'SHIFT',
      'scheduleSnapshot': {'name': 'Night'},
      'originalSchedule': {
        'schedule': {'name': 'Morning'},
      },
      'status': 'CANCELLED',
      'cancellationReason': 'Coverage ended',
      'cancelledAt': '2026-10-12T15:00Z',
      'cancellerName': 'Mona',
    });
    expect(record.shiftName, 'Night');
    expect(record.originalShiftName, 'Morning');
    expect(record.active, false);
    expect(record.creatorName, 'Sam');
    expect(record.cancellerName, 'Mona');
  });
  testWidgets('failed save retains an idempotency ID and succeeds on retry', (
    tester,
  ) async {
    final repository = _Repository()..fail = true;
    await tester.pumpWidget(
      app(
        ScheduleExceptionDialog(
          repository: repository,
          workspaceId: 'workspace',
          timezone: 'Africa/Cairo',
          isCurrent: () => true,
          templates: const [],
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Public holiday');
    await tester.tap(find.text('Save exception'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Save exception'));
    await tester.pumpAndSettle();
    expect(repository.ids.length, 2);
    expect(repository.ids[0], repository.ids[1]);
    expect(repository.kind, 'HOLIDAY');
  });
  testWidgets('switching scope while a dialog is open blocks its submission', (
    tester,
  ) async {
    var current = true;
    final repository = _Repository();
    await tester.pumpWidget(
      app(
        ScheduleExceptionDialog(
          repository: repository,
          workspaceId: 'workspace',
          timezone: 'UTC',
          isCurrent: () => current,
          templates: const [],
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Public holiday');
    current = false;
    await tester.tap(find.text('Save exception'));
    await tester.pumpAndSettle();
    expect(repository.ids, isEmpty);
  });
  testWidgets(
    'Arabic rest-day notice explains the date and has no check-in action on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          const DayExceptionNotices(
            notices: [
              ScheduleExceptionNotice(
                operationalDate: '2026-10-20',
                kind: 'DAY_OFF',
                reason: 'راحة بدل الشيفت السابق',
              ),
            ],
          ),
          arabic: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-10-20'), findsOneWidget);
      expect(
        find.text('لا يُطلب منك تسجيل حضور الشيفت الأساسي في هذا اليوم.'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('report exports use the saved occurrence interval', () async {
    final file = await AttendanceReportExporter().create(
      fixtureReport(records: [reportRecord()]),
      format: ReportFileFormat.excel,
      strings: ReportLabels(const AppLocalizations(Locale('en')).text),
    );
    final rows = Excel.decodeBytes(file.bytes).tables['Details']!.rows;
    expect((rows[0][8]!.value as TextCellValue).value.text, 'Saved schedule');
    expect(
      (rows[0][9]!.value as TextCellValue).value.text,
      'Schedule exception reason',
    );
    expect((rows[1][8]!.value as TextCellValue).value.text, contains('10:00'));
    expect(
      (rows[1][8]!.value as TextCellValue).value.text,
      contains('6:00 PM'),
    );
  });
  testWidgets(
    'manager holiday history displays names and loads the next page',
    (tester) async {
      final repository = _Repository();
      const scope = FeatureSessionScope(
        userId: 'user',
        workspaceId: 'workspace',
        membershipId: 'manager',
        timezone: 'UTC',
        role: WorkspaceRole.manager,
      );
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: ScheduleExceptionsSection(
              scope: scope,
              repository: repository,
              fixedShifts: _FixedRepository(),
              isCurrent: () => true,
              canEdit: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Created by Sam'), findsOneWidget);
      expect(find.text('Add workspace holiday'), findsNothing);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(repository.pages, [1, 2]);
      expect(find.text('Public holiday'), findsNWidgets(2));
    },
  );
  testWidgets('Arabic holiday editor fits compact width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: ScheduleExceptionDialog(
            repository: _Repository(),
            workspaceId: 'workspace',
            timezone: 'Africa/Cairo',
            isCurrent: () => true,
            templates: const [],
          ),
        ),
        arabic: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('عطلة مساحة العمل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
