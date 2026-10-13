import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/eligibility_tile.dart';
import 'package:shiftly/features/team_work/data/api_team_work_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/correction_approval_dialog.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/missed_attendance_request_dialog.dart';
import 'package:shiftly/features/team_work/presentation/utils/attendance_review_instants.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card.dart';

final _start = DateTime.utc(2026, 10, 1, 8),
    _end = DateTime.utc(2026, 10, 1, 16);
EligibleShiftOccurrence _entry({bool used = false, bool pending = false}) =>
    EligibleShiftOccurrence(
      template: ShiftTemplate(
        id: 'template',
        workspaceId: 'workspace',
        name: 'Morning',
        color: '#334155',
        startMinute: 480,
        endMinute: 960,
        graceMinutes: 5,
        allowedEarlyCheckInMinutes: 30,
        allowedLateCheckInMinutes: 120,
        minimumWorkMinutes: 420,
        active: true,
        overnight: false,
        createdAt: _start,
        updatedAt: _start,
      ),
      occurrenceKind: 'BASELINE',
      assignmentId: 'assignment',
      timezone: 'UTC',
      operationalDate: '2026-10-01',
      scheduledStartAt: _start,
      scheduledEndAt: _end,
      checkInWindowStart: _start.subtract(const Duration(minutes: 30)),
      checkInWindowEnd: _start.add(const Duration(hours: 2)),
      classification: AttendanceClassification.late,
      lateMinutes: 2133,
      recommended: false,
      alreadyUsed: used,
      pendingReview: pending,
    );
Map<String, Object?> _requestJson({String status = 'PENDING'}) => {
  'id': 'request',
  'attendanceId': null,
  'status': status,
  'requester': {
    'profile': {'fullName': 'Sam'},
  },
  'reasonKind': 'FORGOT_TO_RECORD',
  'reason': 'Forgot to record attendance',
  'originalClockInAt': null,
  'originalClockOutAt': null,
  'requestedClockInAt': _start.toIso8601String(),
  'requestedClockOutAt': _end.toIso8601String(),
  'occurrenceSnapshot': {
    'schedule': {'name': 'Morning'},
    'operationalDate': '2026-10-01',
  },
};

class _Repository implements TeamWorkRepository {
  int submissions = 0;
  String? kind, reason;
  DateTime? approvedStart, approvedEnd;
  String? note;
  bool fail = false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> requestMissedAttendance(
    String workspaceId, {
    String? assignmentId,
    String? extraAuthorizationId,
    required String operationalDate,
    required String reasonKind,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) async {
    submissions++;
    if (fail) throw const ApiException(message: 'Try again');
    expect(workspaceId, 'workspace');
    expect(assignmentId, 'assignment');
    expect(extraAuthorizationId, isNull);
    expect(operationalDate, '2026-10-01');
    expect(clockIn, _start);
    expect(clockOut, _end);
    kind = reasonKind;
    this.reason = reason;
  }

  @override
  Future<void> reviewCorrection(
    String workspaceId,
    String id, {
    required bool approve,
    String? note,
    DateTime? clockIn,
    DateTime? clockOut,
  }) async {
    expect(approve, isTrue);
    expect(workspaceId, 'workspace');
    expect(id, 'request');
    approvedStart = clockIn;
    approvedEnd = clockOut;
    this.note = note;
  }
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _screen(Widget child, {bool arabic = false}) => MaterialApp(
  locale: Locale(arabic ? 'ar' : 'en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget _dialogScreen(Widget child, {bool arabic = false}) => _screen(
  Builder(
    builder: (context) => TextButton(
      onPressed: () =>
          showDialog<void>(context: context, builder: (_) => child),
      child: const Text('Open dialog'),
    ),
  ),
  arabic: arabic,
);

void main() {
  testWidgets('employee and manager dialogs fit a compact Arabic screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    for (final dialog in <Widget>[
      MissedAttendanceRequestDialog(
        entry: _entry(),
        workspaceId: 'workspace',
        timezone: 'UTC',
        repository: repository,
      ),
      CorrectionApprovalDialog(
        request: CorrectionRequest.fromJson(_requestJson()),
        repository: repository,
        workspaceId: 'workspace',
        timezone: 'UTC',
      ),
    ]) {
      await tester.pumpWidget(_dialogScreen(dialog, arabic: true));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
    }
  });
  test(
    'review time picker rejects Cairo DST gaps and exposes both fold instants',
    () {
      expect(
        attendanceReviewInstants(DateTime(2026, 4, 24), 0, 30, 'Africa/Cairo'),
        isEmpty,
      );
      final fold = attendanceReviewInstants(
        DateTime(2026, 10, 29),
        23,
        30,
        'Africa/Cairo',
      );
      expect(fold, hasLength(2));
      expect(fold.last.difference(fold.first), const Duration(hours: 1));
      expect(attendanceReviewInstants(DateTime(2026, 10, 1), 12, 0, 'UTC'), [
        DateTime.utc(2026, 10, 1, 12),
      ]);
    },
  );
  for (final arabic in [false, true]) {
    testWidgets(
      'completed unrecorded shift explains missing attendance at mobile width, Arabic: $arabic',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var tapped = false;
        await tester.pumpWidget(
          _screen(
            EligibilityTile(
              entry: _entry(),
              timezone: 'UTC',
              busy: false,
              evaluatedAt: _end.add(const Duration(hours: 1)),
              onReview: () => tapped = true,
            ),
            arabic: arabic,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            arabic ? 'مفيش حضور متسجّل' : 'No attendance recorded',
          ),
          findsWidgets,
        );
        expect(
          find.textContaining(
            arabic
                ? 'حضرت ونسيت تسجّل'
                : 'Did you attend without recording',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('2133'), findsNothing);
        await tester.tap(find.byType(OutlinedButton));
        expect(tapped, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'future and used shifts do not claim missing attendance or offer a review',
    (tester) async {
      for (final (entry, evaluatedAt) in [
        (_entry(), _start.subtract(const Duration(hours: 1))),
        (_entry(used: true), _end),
      ]) {
        await tester.pumpWidget(
          _screen(
            EligibilityTile(
              entry: entry,
              timezone: 'UTC',
              busy: false,
              evaluatedAt: evaluatedAt,
              onReview: () {},
            ),
          ),
        );
        expect(
          find.textContaining('Did you attend without recording'),
          findsNothing,
        );
        expect(find.byType(OutlinedButton), findsNothing);
      }
    },
  );
  testWidgets(
    'pending request offers history and no duplicate submission action',
    (tester) async {
      await tester.pumpWidget(
        _screen(
          EligibilityTile(
            entry: _entry(pending: true),
            timezone: 'UTC',
            busy: false,
            evaluatedAt: _end,
          ),
        ),
      );
      expect(
        find.text('Your request is waiting for your manager’s review.'),
        findsOneWidget,
      );
      expect(find.text('View my requests'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );
  testWidgets(
    'employee must explain request and can retry failed exception submission',
    (tester) async {
      final repository = _Repository()..fail = true;
      await tester.pumpWidget(
        _dialogScreen(
          MissedAttendanceRequestDialog(
            entry: _entry(),
            workspaceId: 'workspace',
            timezone: 'UTC',
            repository: repository,
          ),
        ),
      );
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('send-missed-attendance-request')));
      await tester.pumpAndSettle();
      expect(repository.submissions, 0);
      expect(
        find.text('Please add a reason of at least 5 characters.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('I have an exception or special circumstance').last,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'An approved special circumstance',
      );
      await tester.tap(find.byKey(const Key('send-missed-attendance-request')));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      expect(repository.submissions, 1);
      repository.fail = false;
      await tester.tap(find.byKey(const Key('send-missed-attendance-request')));
      await tester.pumpAndSettle();
      expect(repository.submissions, 2);
      expect(repository.kind, 'EXCEPTION');
      expect(repository.reason, 'An approved special circumstance');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'manager can approve four hours of an eight-hour request with a note',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(
        _dialogScreen(
          CorrectionApprovalDialog(
            request: CorrectionRequest.fromJson(_requestJson()),
            repository: repository,
            workspaceId: 'workspace',
            timezone: 'UTC',
          ),
        ),
      );
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clock out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final timeInputs = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(timeInputs.first, '12');
      await tester.enterText(timeInputs.last, '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-correction-approval')));
      await tester.pumpAndSettle();
      expect(repository.approvedEnd, isNull);
      expect(
        find.text('Explain why the approved times differ from the request.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'Four hours confirmed');
      await tester.tap(find.byKey(const Key('confirm-correction-approval')));
      await tester.pumpAndSettle();
      expect(repository.approvedStart, _start);
      expect(repository.approvedEnd, DateTime.utc(2026, 10, 1, 12));
      expect(repository.note, 'Four hours confirmed');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'approved history displays requested and actually approved hours',
    (tester) async {
      final request = CorrectionRequest.fromJson({
        ..._requestJson(status: 'APPROVED'),
        'attendanceId': 'new-record',
        'approvedClockInAt': _start.toIso8601String(),
        'approvedClockOutAt': DateTime.utc(2026, 10, 1, 12).toIso8601String(),
        'reviewNote': 'Four hours confirmed',
      });
      await tester.pumpWidget(
        _screen(CorrectionRequestCard(request: request, timezone: 'UTC')),
      );
      expect(find.text('Requested period: 8h 0m'), findsOneWidget);
      expect(find.text('Approved period: 4h 0m'), findsOneWidget);
      expect(find.text('No attendance recorded'), findsOneWidget);
      expect(find.text('Four hours confirmed'), findsOneWidget);
    },
  );
  test('API sends occurrence identity, structured reason and manager-approved UTC times', () async {
    final adapter = _Adapter(), dio = Dio();
    dio.httpClientAdapter = adapter;
    addTearDown(dio.close);
    final repository = ApiTeamWorkRepository(dio);
    await repository.requestMissedAttendance(
      'workspace',
      assignmentId: 'assignment',
      operationalDate: '2026-10-01',
      reasonKind: 'FORGOT_TO_RECORD',
      clockIn: _start,
      clockOut: _end,
      reason: ' Forgot to record ',
    );
    expect(
      adapter.requests.first.path,
      '/workspaces/workspace/team-work/corrections/missed',
    );
    expect(adapter.requests.first.data, {
      'assignmentId': 'assignment',
      'operationalDate': '2026-10-01',
      'reasonKind': 'FORGOT_TO_RECORD',
      'clockInAt': _start.toIso8601String(),
      'clockOutAt': _end.toIso8601String(),
      'reason': 'Forgot to record',
    });
    await repository.reviewCorrection(
      'workspace',
      'request',
      approve: true,
      clockIn: _start,
      clockOut: DateTime.parse('2026-10-01T15:00:00+03:00'),
      note: 'Four hours confirmed',
    );
    expect(adapter.requests.last.data, {
      'decision': 'APPROVED',
      'note': 'Four hours confirmed',
      'clockInAt': _start.toIso8601String(),
      'clockOutAt': '2026-10-01T12:00:00.000Z',
    });
  });
}
