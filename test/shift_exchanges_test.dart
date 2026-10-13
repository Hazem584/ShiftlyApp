import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_type.dart';
import 'package:shiftly/features/team_work/data/api_shift_exchange_repository.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/create_exchange_dialog.dart';
import 'package:shiftly/features/team_work/presentation/widgets/exchange_request_card.dart';
import 'package:shiftly/features/team_work/presentation/widgets/shift_exchanges_view.dart';

Map<String, Object?> evidence(
  String employee, {
  String date = '2026-10-20',
  bool expected = true,
}) => {
  'employeeMembershipId': employee,
  'name': employee == 'a' ? 'Adel' : 'Mona',
  'assignmentId': 'assignment-$employee',
  'operationalDate': date,
  'expected': expected,
  'schedule': {
    'id': employee == 'a' ? 'morning' : 'night',
    'name': employee == 'a' ? 'Morning' : 'Night',
    'timezone': 'UTC',
  },
  'scheduledStartAt': '${date}T08:00:00Z',
  'scheduledEndAt': '${date}T16:00:00Z',
  'checkInWindowStart': '${date}T07:30:00Z',
  'exceptionId': null,
};
Map<String, Object?> requestJson({
  String status = 'PENDING_PEER',
  String workspace = 'w',
}) => {
  'id': 'request',
  'workspaceId': workspace,
  'requesterMembershipId': 'a',
  'targetMembershipId': 'b',
  'kind': 'SWAP',
  'status': status,
  'reason': 'Covering customer service',
  'requesterDate': '2026-10-20',
  'targetDate': '2026-10-20',
  'requesterSnapshot': evidence('a'),
  'targetSnapshot': evidence('b'),
  'expiresAt': '2099-10-20T07:30:00Z',
  'createdAt': '2026-10-13T08:00:00Z',
};

class Repository implements ShiftExchangeRepository {
  final decisions = <String>[], clientIds = <String>[];
  bool fail = false;
  String status = 'PENDING_PEER';
  @override
  Future<WorkPage<ShiftExchange>> list(
    String workspaceId, {
    int page = 1,
  }) async =>
      WorkPage([ShiftExchange.fromJson(requestJson(status: status))], 1);
  @override
  Future<WorkPage<ExchangeColleague>> colleagues(
    String workspaceId, {
    int page = 1,
  }) async => const WorkPage([ExchangeColleague('b', 'Mona')], 1);
  @override
  Future<Map<String, Object?>> occurrence(
    String workspaceId,
    String membershipId,
    String date,
  ) async => evidence(membershipId, date: date);
  @override
  Future<void> create(
    String workspaceId, {
    required String clientId,
    required String targetMembershipId,
    required String kind,
    required String requesterDate,
    required String targetDate,
    required String reason,
    required Map<String, Object?> requesterSnapshot,
    required Map<String, Object?> targetSnapshot,
  }) async {
    clientIds.add(clientId);
    expect(requesterSnapshot['employeeMembershipId'], 'a');
    expect(targetSnapshot['employeeMembershipId'], 'b');
    if (fail) throw const ApiException(message: 'Try again');
  }

  @override
  Future<void> decide(
    String workspaceId,
    String id,
    String decision, {
    String? note,
  }) async {
    decisions.add(decision);
    status = decision == 'ACCEPT'
        ? 'PENDING_MANAGER'
        : decision == 'APPROVE'
        ? 'APPROVED'
        : 'REJECTED';
  }
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
  test(
    'API preserves the agreed preview, submission ID and workspace scope',
    () async {
      final dio = Dio();
      RequestOptions? captured;
      var foreign = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            captured = o;
            h.resolve(
              Response<Object?>(
                requestOptions: o,
                statusCode: 200,
                data: o.method == 'GET'
                    ? {
                        'data': [
                          requestJson(workspace: foreign ? 'other' : 'w'),
                        ],
                        'total': 1,
                      }
                    : {},
              ),
            );
          },
        ),
      );
      final repo = ApiShiftExchangeRepository(dio);
      await repo.create(
        'w',
        clientId: 'client',
        targetMembershipId: 'b',
        kind: 'SWAP',
        requesterDate: '2026-10-20',
        targetDate: '2026-10-20',
        reason: 'Coverage reason',
        requesterSnapshot: evidence('a'),
        targetSnapshot: evidence('b'),
      );
      expect(captured!.path, '/workspaces/w/shift-exchanges');
      expect((captured!.data as Map)['requesterSnapshot'], evidence('a'));
      expect((captured!.data as Map)['clientRequestId'], 'client');
      foreign = true;
      await expectLater(repo.list('w'), throwsA(isA<ApiException>()));
      dio.close();
    },
  );
  test('new notification types retain their server values', () {
    for (final type in [
      'SHIFT_EXCHANGE_REQUESTED',
      'SHIFT_EXCHANGE_UPDATED',
      'FIXED_SHIFT_REMINDER',
      'CLOCK_OUT_REMINDER',
    ]) {
      expect(NotificationType.parse(type).apiValue, type);
    }
  });
  testWidgets(
    'only the target employee can accept; manager approval appears after consent',
    (tester) async {
      final repo = Repository();
      await tester.pumpWidget(
        app(
          ShiftExchangesView(
            workspaceId: 'w',
            membershipId: 'b',
            timezone: 'UTC',
            manager: false,
            repository: repo,
            isCurrent: () => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept request'));
      await tester.pumpAndSettle();
      expect(repo.decisions, ['ACCEPT']);
      expect(find.text('Accept request'), findsNothing);
      await tester.pumpWidget(
        app(
          ShiftExchangesView(
            key: const ValueKey('manager'),
            workspaceId: 'w',
            membershipId: 'manager',
            timezone: 'UTC',
            manager: true,
            repository: repo,
            isCurrent: () => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve schedule change'));
      await tester.pumpAndSettle();
      expect(repo.decisions, ['ACCEPT', 'APPROVE']);
    },
  );
  testWidgets('another employee sees history but cannot accept', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ExchangeRequestCard(
          request: ShiftExchange.fromJson(requestJson()),
          membershipId: 'other',
          manager: false,
          timezone: 'UTC',
          busy: false,
          onDecision: (_) => fail('No action expected'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accept request'), findsNothing);
    expect(find.text('Cancel request'), findsNothing);
  });
  testWidgets('expired requests have no approval action', (tester) async {
    await tester.pumpWidget(
      app(
        ExchangeRequestCard(
          request: ShiftExchange.fromJson({
            ...requestJson(status: 'PENDING_MANAGER'),
            'expiresAt': '2020-01-01T00:00Z',
          }),
          membershipId: 'manager',
          manager: true,
          timezone: 'UTC',
          busy: false,
          onDecision: (_) => fail('Expired action'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve schedule change'), findsNothing);
    expect(find.text('Request expired'), findsOneWidget);
  });
  testWidgets(
    'failed employee submission retains a retry ID and requires a preview',
    (tester) async {
      final repo = Repository()..fail = true;
      await tester.pumpWidget(
        app(
          CreateExchangeDialog(
            repository: repo,
            workspaceId: 'w',
            membershipId: 'a',
            timezone: 'UTC',
            isCurrent: () => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colleague'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mona').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Coverage reason');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Send request'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Preview agreed schedules'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send request'));
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(repo.clientIds.length, 2);
      expect(repo.clientIds[0], repo.clientIds[1]);
    },
  );
  testWidgets('Arabic request card fits a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: SingleChildScrollView(
            child: ExchangeRequestCard(
              request: ShiftExchange.fromJson(
                requestJson(status: 'PENDING_MANAGER'),
              ),
              membershipId: 'manager',
              manager: true,
              timezone: 'Africa/Cairo',
              busy: false,
              onDecision: (_) {},
            ),
          ),
        ),
        arabic: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('مستنيين موافقة المدير'), findsOneWidget);
  });
}
