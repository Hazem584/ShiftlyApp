import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_screen.dart';

import 'support/report_fixtures.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    AttendanceReportsCubit cubit, {
    Locale locale = const Locale('en'),
    _Delivery? delivery,
    AttendanceReportExporter? exporter,
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AttendanceReportsScreen(
            fileDelivery: delivery ?? _Delivery(),
            exporter: exporter ?? AttendanceReportExporter(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Arabic report renders on a narrow phone with no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = AttendanceReportsCubit(
      _Repository(),
      now: () => DateTime.utc(2026, 10, 10),
    )..bindSession(reportScope);
    addTearDown(cubit.close);
    await mount(tester, cubit, locale: const Locale('ar'));
    expect(find.text('تقارير الحضور'), findsOneWidget);
    expect(find.text('شهري'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'employee filter matches on-screen data and the exported workbook',
    (tester) async {
      final cubit = AttendanceReportsCubit(
        _Repository(),
        now: () => DateTime.utc(2026, 10, 10),
      )..bindSession(reportScope);
      addTearDown(cubit.close);
      final delivery = _Delivery();
      await mount(tester, cubit, delivery: delivery);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('منى').last);
      await tester.pumpAndSettle();
      expect(cubit.state.employeeId, 'second');
      await tester.scrollUntilVisible(
        find.byKey(const Key('report-export-excel')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('report-export-excel')));
      await tester.pumpAndSettle();
      expect(delivery.files.single.name, endsWith('_employee.xlsx'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed loading offers retry and never shows export controls', (
    tester,
  ) async {
    final cubit = AttendanceReportsCubit(_Repository(fail: true))
      ..bindSession(reportScope);
    addTearDown(cubit.close);
    await mount(tester, cubit);
    expect(find.text('Unable to load attendance report.'), findsOneWidget);
    expect(find.text('Refresh report'), findsOneWidget);
    expect(find.byKey(const Key('report-export-excel')), findsNothing);
  });
  testWidgets('logout during file generation blocks delivery', (tester) async {
    final cubit = AttendanceReportsCubit(
      _Repository(),
      now: () => DateTime.utc(2026, 10, 10),
    )..bindSession(reportScope);
    addTearDown(cubit.close);
    final delivery = _Delivery();
    final exporter = _DelayedExporter();
    await mount(tester, cubit, delivery: delivery, exporter: exporter);
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-export-excel')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('report-export-excel')));
    await tester.pump();
    cubit.bindSession(null);
    exporter.pending.complete(
      await AttendanceReportExporter().create(
        fixtureReport(),
        format: ReportFileFormat.excel,
        strings: ReportLabels(const AppLocalizations(Locale('en')).text),
      ),
    );
    await tester.pumpAndSettle();
    expect(delivery.files, isEmpty);
    expect(find.byKey(const Key('report-export-excel')), findsNothing);
  });
}

class _Repository implements AttendanceReportRepository {
  _Repository({this.fail = false});
  final bool fail;
  @override
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  }) async {
    if (fail) {
      throw const ApiException(message: 'Unable to load attendance report.');
    }
    return fixtureReport(range: range);
  }
}

class _Delivery implements ReportFileDelivery {
  final files = <ReportExportFile>[];
  @override
  Future<void> deliver(
    ReportExportFile file, {
    required ReportShareOrigin origin,
    required bool Function() isCurrent,
  }) async {
    if (isCurrent()) files.add(file);
  }
}

class _DelayedExporter extends AttendanceReportExporter {
  final pending = Completer<ReportExportFile>();
  @override
  Future<ReportExportFile> create(
    AttendanceReport report, {
    required ReportFileFormat format,
    required ReportLabels strings,
    String? employeeId,
  }) => pending.future;
}
