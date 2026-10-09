import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/manager_performance/data/preferences_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_mutation_intent.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_page.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';

import 'support/delayed_manager_storage.dart';
import 'support/manager_points_fake.dart';

const managerScope = FeatureSessionScope(
  userId: 'u',
  workspaceId: 'w',
  membershipId: 'actor',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.manager,
);
const adjustmentPayload = {
  'pointType': 'GREEN',
  'amount': 1,
  'reason': 'OTHER',
  'explanation': '  Correct evidence  ',
};
Future<void> ready(
  ManagerPerformanceCubit cubit, [
  FeatureSessionScope scope = managerScope,
]) async {
  cubit.bindSession(scope);
  await Future<void>.delayed(Duration.zero);
}

ManagerPointsPage page(List<String> ids, int page, {int pages = 2}) =>
    ManagerPointsPage(
      ids.map((id) => ManagerPointsRecord({'id': id})).toList(),
      pagination: ApiPagination(
        page: page,
        limit: 20,
        total: 40,
        totalPages: pages,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ManagerPointsFake repository;
  late DelayedManagerStorage storage;
  late ManagerPerformanceCubit cubit;
  setUp(() {
    repository = ManagerPointsFake();
    storage = DelayedManagerStorage();
    cubit = ManagerPerformanceCubit(repository, storage);
  });
  tearDown(() => cubit.close());
  test(
    'submission without a UUID field omits the key and preserves payload',
    () async {
      await ready(cubit);
      repository.onMutate = (_, payload, _) async =>
          ManagerPointsRecord({'id': 'canonical', ...payload});
      await cubit.submit('policy/versions', {
        'effectiveFrom': '2099-10-10',
        'explanation': '  Policy evidence  ',
      });
      expect(repository.calls.single['payload'], {
        'effectiveFrom': '2099-10-10',
        'explanation': 'Policy evidence',
      });
      expect(cubit.state.intent, isNull);
      expect(await storage.read(managerScope), isNull);
    },
  );
  test('duplicate taps blocked before persistence and UUID survives timeout/restart', () async {
    await ready(cubit);
    storage.writeGate = Completer<void>();
    repository.onMutate = (_, _, _) async =>
        throw const ApiException(message: 'Timeout', statusCode: 408);
    final first = cubit.submit(
      'adjustments',
      adjustmentPayload,
      target: 'target',
      uuidField: 'clientAdjustmentId',
    );
    await cubit.submit(
      'adjustments',
      adjustmentPayload,
      target: 'target',
      uuidField: 'clientAdjustmentId',
    );
    expect(repository.calls, isEmpty);
    storage.writeGate!.complete();
    await first;
    final saved = cubit.state.intent!;
    expect(saved.payload['explanation'], 'Correct evidence');
    expect(
      saved.payload['clientAdjustmentId'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    final restored = ManagerPerformanceCubit(repository, storage);
    addTearDown(restored.close);
    await ready(restored);
    expect(repository.calls.length, 1); // no automatic submission
    expect(restored.state.intent!.encode(), saved.encode());
    await restored.submit(
      'extra-effort',
      {'reason': 'OTHER'},
      target: 'other',
      uuidField: 'clientAwardId',
    );
    expect(repository.calls.length, 1);
    repository.onMutate = (_, payload, _) async =>
        ManagerPointsRecord({'id': 'canonical', ...payload});
    await restored.recover();
    expect(repository.calls.last['payload'], repository.calls.first['payload']);
    expect(restored.state.intent, isNull);
    expect(await storage.read(managerScope), isNull);
  });
  test('write failure never submits and retry persists first', () async {
    await ready(cubit);
    storage.failWrite = true;
    await cubit.submit(
      'adjustments',
      adjustmentPayload,
      target: 'target',
      uuidField: 'clientAdjustmentId',
    );
    expect(repository.calls, isEmpty);
    expect(cubit.state.canMutate, isFalse);
    storage.failWrite = false;
    await cubit.recover();
    expect(repository.calls.length, 1);
    expect(cubit.state.canMutate, isTrue);
  });
  test('canonical success survives cleanup and refresh failures', () async {
    await ready(cubit);
    repository.onList = (_, _, query) async =>
        page(['existing'], query['page']! as int);
    await cubit.load('summary');
    storage.failClear = true;
    repository.onList = (_, _, _) async =>
        throw const ApiException(message: 'Refresh failed');
    await cubit.submit(
      'adjustments',
      adjustmentPayload,
      target: 'target',
      uuidField: 'clientAdjustmentId',
    );
    expect(cubit.state.intent, isNotNull);
    expect(cubit.state.message, contains('confirmed'));
    expect(
      cubit.state.resources['workspace:summary']!.records.single.id,
      'existing',
    );
    expect(cubit.state.resources['workspace:summary']!.error, 'Refresh failed');
    storage.failClear = false;
    await cubit.recover();
    expect(cubit.state.intent, isNull);
  });
  test(
    'only known endpoint business rejections clear saved requests',
    () async {
      await ready(cubit);
      for (final error in [
        const ApiException(message: 'Forbidden', statusCode: 403),
        const ApiException(
          message: 'Conflict',
          statusCode: 409,
          code: 'POINT_ADJUSTMENT_CONFLICT',
        ),
        const ApiException(
          message: 'Server',
          statusCode: 500,
          code: 'POINTS_BALANCE_INVARIANT_VIOLATION',
        ),
      ]) {
        repository.onMutate = (_, _, _) async => throw error;
        if (cubit.state.intent == null) {
          await cubit.submit(
            'adjustments',
            adjustmentPayload,
            target: 'target',
            uuidField: 'clientAdjustmentId',
          );
        } else {
          await cubit.recover();
        }
        expect(cubit.state.intent, isNotNull);
      }
      repository.onMutate = (_, _, _) async => throw const ApiException(
        message: 'Insufficient balance',
        statusCode: 409,
        code: 'POINTS_BALANCE_INVARIANT_VIOLATION',
      );
      await cubit.recover();
      expect(cubit.state.intent, isNull);
    },
  );
  test('award and both reversals recover exact UUID and payload', () async {
    await ready(cubit);
    for (final resource in [
      'extra-effort',
      'extra-effort/a/reverse',
      'adjustments/a/reverse',
    ]) {
      repository.onMutate = (_, _, _) async =>
          throw const ApiException(message: 'Lost response', statusCode: 503);
      await cubit.submit(
        resource,
        {'reason': 'OTHER', 'explanation': 'Reviewed evidence'},
        target: 'target',
        uuidField: resource == 'extra-effort'
            ? 'clientAwardId'
            : 'clientReversalId',
      );
      final payload = cubit.state.intent!.payload;
      repository.onMutate = (_, value, _) async =>
          ManagerPointsRecord({'id': 'a', ...value});
      await cubit.recover();
      expect(repository.calls.last['payload'], payload);
      expect(cubit.state.intent, isNull);
    }
  });
  test(
    'review ambiguous outcome uses canonical read without another PATCH',
    () async {
      await ready(cubit);
      repository.onMutate = (_, _, _) async =>
          throw const ApiException(message: 'Timeout', statusCode: 408);
      await cubit.submit('disputes/d/review', {
        'decision': 'APPROVED',
        'response': 'Evidence verified',
      }, patch: true);
      await cubit.recover();
      expect(
        cubit.state.intent,
        isNotNull,
      ); // PENDING is not proof of rejection
      repository.onGet = (_, _) async => {
        'id': 'd',
        'status': 'APPROVED',
        'managerResponse': 'Evidence verified',
        'reviewedByMembershipId': 'actor',
      };
      await cubit.recover();
      expect(
        repository.calls.where((call) => call['method'] == 'PATCH').length,
        1,
      );
      expect(cubit.state.intent, isNull);
    },
  );
  test(
    'already reviewed by another manager resolves without resubmission',
    () async {
      await ready(cubit);
      repository.onMutate = (_, _, _) async => throw const ApiException(
        message: 'Reviewed',
        statusCode: 409,
        code: 'POINT_DISPUTE_ALREADY_REVIEWED',
      );
      await cubit.submit('disputes/d/review', {
        'decision': 'APPROVED',
        'response': 'Evidence verified',
      }, patch: true);
      repository.onGet = (_, _) async => {
        'id': 'd',
        'status': 'REJECTED',
        'reviewedByMembershipId': 'other',
      };
      await cubit.recover();
      expect(cubit.state.intent, isNull);
      expect(
        repository.calls.where((call) => call['method'] == 'PATCH').length,
        1,
      );
    },
  );
  test('policy recovery compares version date, settings and actor', () async {
    await ready(cubit);
    repository.onMutate = (_, _, _) async =>
        throw const ApiException(message: 'Timeout');
    const payload = {'effectiveFrom': '2026-10-09', 'blueGreenEquivalent': 2};
    await cubit.submit('policies', payload);
    await cubit.recover();
    expect(cubit.state.intent, isNotNull);
    repository.onList = (_, _, _) async => ManagerPointsPage([
      ManagerPointsRecord({
        'id': 'p',
        'createdByMembershipId': 'actor',
        ...payload,
      }),
    ]);
    await cubit.recover();
    expect(cubit.state.intent, isNull);
    expect(
      repository.calls.where((call) => call['method'] == 'POST').length,
      1,
    );
  });
  test('pagination deduplicates and filters clear earlier results', () async {
    await ready(cubit);
    repository.onList = (_, _, query) async => page(
      query['page'] == 1 ? ['a', 'b'] : ['b', 'c'],
      query['page']! as int,
    );
    await cubit.load('summary');
    await cubit.load('summary', more: true);
    expect(
      cubit.state.resources['workspace:summary']!.records.map(
        (record) => record.id,
      ),
      ['a', 'b', 'c'],
    );
    final gate = Completer<ManagerPointsPage>();
    repository.onList = (_, _, _) => gate.future;
    final changed = cubit.load('summary', query: {'search': 'Other'});
    expect(cubit.state.resources['workspace:summary']!.records, isEmpty);
    gate.complete(page(['other'], 1));
    await changed;
    expect(
      cubit.state.resources['workspace:summary']!.records.single.id,
      'other',
    );
  });
  test('distinct employee resources remain independent and stale workspace results are rejected', () async {
    await ready(cubit);
    final gateA = Completer<ManagerPointsPage>();
    final gateB = Completer<ManagerPointsPage>();
    repository.onList = (_, target, _) =>
        target == 'a' ? gateA.future : gateB.future;
    final a = cubit.load('history', target: 'a');
    final b = cubit.load('history', target: 'b');
    gateB.complete(page(['b-entry'], 1));
    await b;
    expect(cubit.state.resources['a:history']!.records, isEmpty);
    expect(cubit.state.resources['b:history']!.records.single.id, 'b-entry');
    cubit.bindSession(
      const FeatureSessionScope(
        userId: 'u2',
        workspaceId: 'w2',
        membershipId: 'actor2',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.manager,
      ),
    );
    gateA.complete(page(['a-entry'], 1));
    await a;
    expect(cubit.state.resources, isEmpty);
  });
  test(
    'scope switch during persistence cannot submit in former scope',
    () async {
      await ready(cubit);
      storage.writeGate = Completer<void>();
      final action = cubit.submit(
        'adjustments',
        adjustmentPayload,
        target: 'target',
        uuidField: 'clientAdjustmentId',
      );
      cubit.bindSession(null);
      storage.writeGate!.complete();
      await action;
      expect(repository.calls, isEmpty);
      expect(cubit.state.intent, isNull);
      await ready(cubit);
      expect(cubit.state.intent, isNotNull);
      expect(repository.calls, isEmpty);
    },
  );
  test('employee role never obtains manager actions or requests', () async {
    await ready(
      cubit,
      const FeatureSessionScope(
        userId: 'u',
        workspaceId: 'w',
        membershipId: 'e',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.employee,
      ),
    );
    await cubit.load('summary');
    await cubit.submit(
      'adjustments',
      adjustmentPayload,
      target: 'target',
      uuidField: 'clientAdjustmentId',
    );
    expect(cubit.state.scope, isNull);
    expect(repository.calls, isEmpty);
  });
  test('server-confirmed manager access loss clears data and blocks stale scope rebind', () async {
    await ready(cubit);
    repository.onList = (_, _, _) async => page(['private'], 1);
    await cubit.load('summary');
    repository.onList = (_, _, _) async => throw const ApiException(
      message: 'Role lost',
      statusCode: 403,
      code: 'MANAGER_ROLE_REQUIRED',
    );
    await cubit.load('summary');
    expect(cubit.state.scope, isNull);
    expect(cubit.state.resources, isEmpty);
    cubit.bindSession(managerScope);
    expect(cubit.state.scope, isNull);
  });
  test(
    'duplicate loads suppressed and repeated invalidations coalesce once',
    () async {
      await ready(cubit);
      final gate = Completer<ManagerPointsPage>();
      repository.onList = (_, _, _) => gate.future;
      final first = cubit.load('summary');
      await cubit.load('summary');
      cubit.invalidate();
      cubit.invalidate();
      cubit.invalidate();
      expect(repository.calls.length, 1);
      repository.onList = (_, _, _) async => page(['fresh'], 1);
      gate.complete(page(['old'], 1));
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls.length, 2);
      expect(
        cubit.state.resources['workspace:summary']!.records.single.id,
        'fresh',
      );
    },
  );
  test('SharedPreferences restart recovery isolates user workspace actor and target action', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final realStorage = PreferencesManagerIntentStorage(prefs);
    final intent = ManagerMutationIntent(
      resource: 'adjustments/a/reverse',
      target: 'employee',
      payload: {
        'clientReversalId': 'saved',
        'reason': 'OTHER',
        'explanation': 'Verified reversal',
      },
    );
    await realStorage.write(managerScope, intent.encode());
    final restarted = PreferencesManagerIntentStorage(prefs);
    expect(
      ManagerMutationIntent.decode((await restarted.read(managerScope))!)
          .target,
      'employee',
    );
    expect(
      await restarted.read(
        const FeatureSessionScope(
          userId: 'other',
          workspaceId: 'w',
          membershipId: 'actor',
          timezone: 'Etc/UTC',
          role: WorkspaceRole.manager,
        ),
      ),
      isNull,
    );
    await restarted.clear(managerScope, 'different');
    expect(await restarted.read(managerScope), isNotNull);
    await restarted.clear(managerScope, intent.encode());
    expect(await restarted.read(managerScope), isNull);
  });
}
