import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/points/data/api_points_repository.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/points_repository.dart';
import 'package:shiftly/features/points/data/redemption_intent_storage.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/points/presentation/screens/my_performance_screen.dart';

const workspaceId = 'c551356a-e456-4a3e-a49a-9dd0caa7e790';

Map<String, Object?> walletJson({int green = 8, int red = 1}) => {
  'workspace': {
    'id': workspaceId,
    'name': 'Cairo Studio',
    'timezone': 'Africa/Cairo',
  },
  'green': {
    'earned': 6,
    'bonuses': 2,
    'adjusted': 0,
    'redeemed': 0,
    'available': green,
  },
  'black': {'total': 2, 'currentMonth': 1},
  'red': {'compensated': 0, 'active': red},
  'orange': {'total': 1, 'currentMonth': 1},
  'blue': {'total': 3, 'currentMonth': 2},
  'streak': {
    'current': 4,
    'best': 8,
    'onTimeCurrent': 3,
    'onTimeBest': 7,
    'nextRewardAt': 5,
  },
  'policy': {
    'greenCostPerRedCompensation': 5,
    'monthlyRedCompensationLimit': 2,
    'remainingMonthlyCompensations': 2,
    'disputeWindowHours': 48,
  },
};

Map<String, Object?> entryJson({
  String id = 'entry-1',
  String type = 'GREEN',
}) => {
  'id': id,
  'workspaceId': workspaceId,
  'employeeMembershipId': 'member-1',
  'pointType': type,
  'amount': 1,
  'reason': 'ATTENDANCE_COMPLETED',
  'sourceKey': 'source-1',
  'policyVersionId': 'policy-1',
  'operationalDate': '2026-10-07',
  'createdAt': '2026-10-07T20:00:00.000Z',
};

Map<String, Object?> dayJson({String status = 'PENDING'}) => {
  'operationalDate': '2026-10-07',
  'status': status,
  'extraEffort': true,
  'templateName': 'Evening',
  'clockInAt': '2026-10-07T16:00:00.000Z',
  'clockOutAt': null,
  'workDurationMinutes': null,
  'lateMinutes': 0,
  'pointChanges': [
    {'pointType': 'BLUE', 'amount': 1},
  ],
};

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object value, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class FakePointsRepository implements PointsRepository {
  PointsWallet wallet = PointsWallet.fromJson(walletJson());
  List<PerformanceDay> calendar = [PerformanceDay.fromJson(dayJson())];
  List<PointLedgerEntry> entries = [PointLedgerEntry.fromJson(entryJson())];
  List<Achievement> achievements = [];
  Object? walletError;
  Object? achievementError;
  final redemptions = <RedemptionIntent>[];
  Completer<void>? redemptionCompleter;
  Object? redemptionError;
  int walletLoads = 0;
  Future<List<PerformanceDay>> Function(int year, int month)? calendarLoader;
  Future<PointsHistoryPage> Function(int page, int limit)? historyLoader;

  @override
  Future<List<Achievement>> loadAchievements(String workspaceId) async {
    if (achievementError case final error?) throw error;
    return achievements;
  }

  @override
  Future<List<PerformanceDay>> loadCalendar(
    String workspaceId,
    int year,
    int month,
  ) async => calendarLoader?.call(year, month) ?? calendar;

  @override
  Future<PointsHistoryPage> loadHistory(
    String workspaceId, {
    required int page,
    required int limit,
  }) async =>
      historyLoader?.call(page, limit) ??
      PointsHistoryPage(
        data: entries,
        pagination: ApiPagination(
          page: page,
          limit: limit,
          total: entries.length,
          totalPages: 2,
        ),
      );

  @override
  Future<PointsWallet> loadWallet(String workspaceId) async {
    walletLoads++;
    if (walletError case final error?) throw error;
    return wallet;
  }

  @override
  Future<void> redeem(RedemptionIntent intent) async {
    redemptions.add(intent);
    if (redemptionError case final error?) throw error;
    await redemptionCompleter?.future;
  }
}

const employeeScope = FeatureSessionScope(
  userId: 'user-1',
  workspaceId: workspaceId,
  membershipId: 'member-1',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
  workspaceName: 'Cairo Studio',
);

void main() {
  group('points parsing', () {
    test('wallet parses authoritative balances and policy ratio', () {
      final wallet = PointsWallet.fromJson(walletJson());
      expect(wallet.green.available, 8);
      expect(wallet.red.active, 1);
      expect(wallet.black.currentMonth, 1);
      expect(wallet.greenCostPerRed, 5);
      expect(wallet.maxRedeemable, 1);
    });

    test('unknown enums fall back and operational date stays date-only', () {
      expect(pointTypeFromJson('PURPLE'), PointType.unknown);
      expect(achievementTypeFromJson('FUTURE_BADGE'), AchievementType.unknown);
      final entry = PointLedgerEntry.fromJson(entryJson(type: 'FUTURE_POINT'));
      expect(entry.type, PointType.unknown);
      expect(entry.operationalDate?.value, '2026-10-07');
      expect(() => OperationalDate.parse('2026-02-30'), throwsFormatException);
    });

    test('pending remains unresolved and extra effort is an overlay', () {
      final day = PerformanceDay.fromJson(dayJson());
      expect(day.status, PerformanceStatus.pending);
      expect(day.status, isNot(PerformanceStatus.absent));
      expect(day.extraEffort, isTrue);
      expect(day.pointChanges.single.type, PointType.blue);
      expect(
        PerformanceDay.fromJson(dayJson(status: 'APPROVED_LEAVE')).status,
        PerformanceStatus.excused,
      );
    });
  });

  test(
    'repository uses exact employee endpoints and bounded pagination',
    () async {
      final adapter = _Adapter((options) {
        if (options.path.endsWith('/calendar')) {
          return jsonResponse([dayJson()]);
        }
        if (options.path.endsWith('/history')) {
          return jsonResponse({
            'data': [entryJson()],
            'pagination': {
              'page': 1,
              'limit': 100,
              'total': 1,
              'totalPages': 1,
            },
          });
        }
        if (options.path.endsWith('/achievements')) return jsonResponse([]);
        if (options.method == 'POST') {
          return jsonResponse({
            'id': 'redemption',
            ...Map<String, Object>.from(options.data as Map),
          });
        }
        return jsonResponse(walletJson());
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = ApiPointsRepository(dio);
      await repository.loadWallet(workspaceId);
      await repository.loadCalendar(workspaceId, 2026, 10);
      final page = await repository.loadHistory(
        workspaceId,
        page: 1,
        limit: 999,
      );
      await repository.loadAchievements(workspaceId);
      const intent = RedemptionIntent(
        workspaceId: workspaceId,
        redPoints: 1,
        clientRedemptionId: 'b7208638-d57a-4da9-a073-f41987ff3d52',
      );
      await repository.redeem(intent);
      expect(adapter.requests.map((r) => r.uri.path), [
        '/api/v1/points/me',
        '/api/v1/points/me/calendar',
        '/api/v1/points/me/history',
        '/api/v1/points/me/achievements',
        '/api/v1/points/me/redemptions',
      ]);
      expect(adapter.requests[1].queryParameters, {
        'workspaceId': workspaceId,
        'year': 2026,
        'month': 10,
      });
      expect(adapter.requests[2].queryParameters['limit'], 100);
      expect(page.data.single.id, 'entry-1');
      expect(adapter.requests.last.data, intent.toJson());
    },
  );

  test(
    'repository requires the original canonical redemption payload',
    () async {
      const intent = RedemptionIntent(
        workspaceId: workspaceId,
        redPoints: 1,
        clientRedemptionId: 'original-key',
      );
      Object response = {'id': 'operation'};
      final adapter = _Adapter((_) => jsonResponse(response));
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = ApiPointsRepository(dio);
      await expectLater(
        repository.redeem(intent),
        throwsA(isA<ApiException>()),
      );
      response = {
        'id': 'operation',
        ...intent.toJson(),
        'clientRedemptionId': 'other-key',
      };
      await expectLater(
        repository.redeem(intent),
        throwsA(isA<ApiException>()),
      );
      response = {'id': 'operation', ...intent.toJson()};
      await repository.redeem(intent);
      expect(
        adapter.requests.map((r) => r.data).toList(),
        List.filled(3, intent.toJson()),
      );
    },
  );

  group('points cubit', () {
    test('loads partial data without erasing successful wallet', () async {
      final repository = FakePointsRepository()
        ..achievementError = const ApiException(message: 'Badges unavailable');
      final cubit = PointsCubit(repository, uuidV4: () => 'uuid');
      cubit.bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.wallet, isNotNull);
      expect(cubit.state.partialFailure?.message, 'Badges unavailable');
      expect(cubit.state.history, isNotEmpty);
      await cubit.close();
    });

    test('workspace switch clears old data and reloads', () async {
      final repository = FakePointsRepository();
      final cubit = PointsCubit(repository);
      cubit.bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      cubit.bindSession(
        const FeatureSessionScope(
          userId: 'user-1',
          workspaceId: 'workspace-2',
          membershipId: 'member-2',
          timezone: 'Etc/UTC',
          role: WorkspaceRole.employee,
        ),
      );
      expect(cubit.state.initialLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(repository.walletLoads, 2);
      await cubit.close();
    });

    test('prevents duplicate redemption and refreshes server truth', () async {
      final repository = FakePointsRepository()
        ..redemptionCompleter = Completer<void>();
      final cubit = PointsCubit(repository, uuidV4: () => 'stable-uuid');
      cubit.bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      final first = cubit.redeem(1);
      await Future<void>.delayed(Duration.zero);
      await cubit.redeem(1);
      expect(repository.redemptions, hasLength(1));
      expect(repository.redemptions.single.clientRedemptionId, 'stable-uuid');
      repository.redemptionCompleter!.complete();
      await first;
      expect(repository.walletLoads, 2);
      expect(cubit.state.redemptionSucceeded, isTrue);
      await cubit.close();
    });

    test('transport retry reuses identical UUID and normalized body', () async {
      final repository = FakePointsRepository()
        ..redemptionError = const ApiException(
          message: 'offline',
          kind: FailureKind.network,
        );
      var generated = 0;
      final cubit = PointsCubit(
        repository,
        uuidV4: () => 'stable-${++generated}',
      );
      cubit.bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      await cubit.redeem(1);
      expect(cubit.state.canRetryRedemption, isTrue);
      repository.redemptionError = null;
      await cubit.redeem(1, retry: true);
      expect(repository.redemptions, hasLength(2));
      expect(repository.redemptions[0], repository.redemptions[1]);
      expect(generated, 1);
      await cubit.close();
    });

    test('domain conflict is explicit and does not retain retry key', () async {
      final repository = FakePointsRepository()
        ..redemptionError = const ApiException(
          message: 'not enough green',
          statusCode: 409,
          code: 'POINTS_INSUFFICIENT_GREEN',
          kind: FailureKind.validation,
        );
      final cubit = PointsCubit(repository, uuidV4: () => 'intent-id');
      cubit.bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      await cubit.redeem(1);
      expect(cubit.state.domainCode, 'POINTS_INSUFFICIENT_GREEN');
      expect(cubit.state.canRetryRedemption, isFalse);
      await cubit.close();
    });

    test('restores an uncertain redemption and retries the same key', () async {
      final storage = MemoryRedemptionIntentStorage();
      final firstRepository = FakePointsRepository()
        ..redemptionError = const ApiException(
          message: 'response lost',
          kind: FailureKind.network,
        );
      final first = PointsCubit(
        firstRepository,
        intentStorage: storage,
        uuidV4: () => 'durable-key',
      )..bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      await first.redeem(1);
      expect(first.state.hasUnresolvedRedemption, isTrue);
      await first.close();

      final recoveredRepository = FakePointsRepository();
      final recovered = PointsCubit(
        recoveredRepository,
        intentStorage: storage,
        uuidV4: () => 'must-not-be-used',
      )..bindSession(employeeScope);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(recovered.state.canRetryRedemption, isTrue);
      await recovered.redeem(1, retry: true);
      expect(
        recoveredRepository.redemptions.single.clientRedemptionId,
        'durable-key',
      );
      expect(recovered.state.redemptionSucceeded, isTrue);
      await recovered.close();
    });

    test(
      'blocks a fresh action while an earlier intent is unresolved',
      () async {
        final repository = FakePointsRepository()
          ..redemptionError = const ApiException(
            message: 'offline',
            kind: FailureKind.network,
          );
        var generated = 0;
        final cubit = PointsCubit(
          repository,
          uuidV4: () => 'key-${++generated}',
        )..bindSession(employeeScope);
        await Future<void>.delayed(Duration.zero);
        await cubit.redeem(1);
        await cubit.redeem(1);
        expect(repository.redemptions, hasLength(1));
        expect(generated, 1);
        await cubit.close();
      },
    );

    test(
      'logout clears memory without submitting another scope intent',
      () async {
        final storage = MemoryRedemptionIntentStorage();
        await storage.write(
          employeeScope,
          const RedemptionIntent(
            workspaceId: workspaceId,
            redPoints: 1,
            clientRedemptionId: 'scope-a-key',
          ),
        );
        final repository = FakePointsRepository();
        final cubit = PointsCubit(repository, intentStorage: storage)
          ..bindSession(employeeScope);
        await Future<void>.delayed(Duration.zero);
        cubit.bindSession(null);
        expect(cubit.state.hasUnresolvedRedemption, isFalse);
        cubit.bindSession(
          const FeatureSessionScope(
            userId: 'user-2',
            workspaceId: 'workspace-2',
            membershipId: 'member-2',
            timezone: 'Etc/UTC',
            role: WorkspaceRole.employee,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(repository.redemptions, isEmpty);
        await cubit.close();
      },
    );

    test(
      'out-of-order month responses cannot replace the selected month',
      () async {
        final repository = FakePointsRepository();
        final october = Completer<List<PerformanceDay>>();
        final november = Completer<List<PerformanceDay>>();
        var controlled = false;
        repository.calendarLoader = (year, month) {
          if (!controlled) return Future.value(repository.calendar);
          return month == 10 ? october.future : november.future;
        };
        final cubit = PointsCubit(repository)..bindSession(employeeScope);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        controlled = true;
        final old = cubit.changeMonth(DateTime(2026, 10));
        final latest = cubit.changeMonth(DateTime(2026, 11));
        november.complete([
          PerformanceDay.fromJson({
            ...dayJson(),
            'operationalDate': '2026-11-03',
          }),
        ]);
        await latest;
        october.complete([PerformanceDay.fromJson(dayJson())]);
        await old;
        expect(cubit.state.visibleMonth?.month, 11);
        expect(cubit.state.visibleCalendar.single.date.month, 11);
        await cubit.close();
      },
    );
  });

  testWidgets('320 width renders semantics, legend and pending details', (
    tester,
  ) async {
    final repository = FakePointsRepository()..entries = [];
    final cubit = PointsCubit(repository);
    cubit.bindSession(employeeScope);
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: MyPerformanceScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('calendar-legend')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'GREEN available balance: 8')),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel(RegExp(r'Day 7, Pending')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('This day is unresolved. It is not recorded as an absence.'),
      findsOneWidget,
    );
  });

  testWidgets('loading skeleton is explicit', (tester) async {
    final cubit = PointsCubit(FakePointsRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: MyPerformanceScreen()),
        ),
      ),
    );
    expect(
      find.byKey(const Key('performance-loading-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets(
    'wide dark theme and scaled text support redemption confirmation',
    (tester) async {
      final repository = FakePointsRepository();
      final cubit = PointsCubit(repository, uuidV4: () => 'widget-intent');
      cubit.bindSession(employeeScope);
      tester.view.physicalSize = const Size(720, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: BlocProvider.value(
              value: cubit,
              child: const Scaffold(body: MyPerformanceScreen()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('redeem-red-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('confirm-redemption')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('confirm-redemption')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-redemption')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(repository.redemptions.single.clientRedemptionId, 'widget-intent');
    },
  );
}
