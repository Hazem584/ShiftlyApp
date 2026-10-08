import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

import 'points_feature_test.dart' show FakePointsRepository, employeeScope;
import 'support/delayed_redemption_storage.dart';

Future<void> _settleStorage() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'two calls before delayed persistence create one UUID and one submission',
    () async {
      final storage = DelayedRedemptionStorage()..writeGate = Completer<void>();
      final repository = FakePointsRepository();
      var ids = 0;
      final cubit = PointsCubit(
        repository,
        intentStorage: storage,
        uuidV4: () => 'key-${++ids}',
      )..bindSession(employeeScope);
      await _settleStorage();
      final first = cubit.redeem(1);
      await storage.writeStarted.future;
      await cubit.redeem(1);
      expect(ids, 1);
      expect(repository.redemptions, isEmpty);
      storage.writeGate!.complete();
      await first;
      expect(repository.redemptions, hasLength(1));
      await cubit.close();
    },
  );
  test(
    'fresh action waits for restoration and write failure releases the claim',
    () async {
      final storage = DelayedRedemptionStorage()..readGate = Completer<void>();
      final repository = FakePointsRepository();
      var ids = 0;
      final cubit = PointsCubit(
        repository,
        intentStorage: storage,
        uuidV4: () => 'key-${++ids}',
      )..bindSession(employeeScope);
      await cubit.redeem(1);
      expect(ids, 0);
      storage.readGate!.complete();
      await _settleStorage();
      storage.failWrite = true;
      await cubit.redeem(1);
      expect(repository.redemptions, isEmpty);
      expect(cubit.state.redeeming, isFalse);
      storage.failWrite = false;
      await cubit.redeem(1);
      expect(repository.redemptions, hasLength(1));
      await cubit.close();
    },
  );
  test('switch while saving cannot submit in another scope or release its restore claim', () async {
    final storage = DelayedRedemptionStorage()..writeGate = Completer<void>();
    final repository = FakePointsRepository();
    final cubit = PointsCubit(
      repository,
      intentStorage: storage,
      uuidV4: () => 'saved-key',
    )..bindSession(employeeScope);
    await _settleStorage();
    final old = cubit.redeem(1);
    await storage.writeStarted.future;
    cubit.bindSession(
      const FeatureSessionScope(
        userId: 'other',
        workspaceId: 'other-workspace',
        membershipId: 'other-member',
        timezone: 'UTC',
        role: WorkspaceRole.employee,
      ),
    );
    storage.readGate = Completer<void>();
    cubit.bindSession(
      employeeScope,
    ); // restore must also wait for the old write
    storage.writeGate!.complete();
    await old;
    await cubit.redeem(1);
    expect(repository.redemptions, isEmpty);
    storage.readGate!.complete();
    await _settleStorage();
    expect(cubit.state.hasUnresolvedRedemption, isTrue);
    await cubit.redeem(1, retry: true);
    expect(repository.redemptions.single.clientRedemptionId, 'saved-key');
    await cubit.close();
  });
  test('canonical success plus cleanup failure survives restart with the original key', () async {
    final storage = DelayedRedemptionStorage()..failClear = true;
    final repository = FakePointsRepository();
    final first = PointsCubit(
      repository,
      intentStorage: storage,
      uuidV4: () => 'canonical-key',
    )..bindSession(employeeScope);
    await _settleStorage();
    await first.redeem(1);
    expect(first.state.redemptionSucceeded, isTrue);
    expect(first.state.hasUnresolvedRedemption, isTrue);
    await first.redeem(1);
    expect(repository.redemptions, hasLength(1));
    await first.close();
    storage.failClear = false;
    final recovered = PointsCubit(
      repository,
      intentStorage: storage,
      uuidV4: () => 'never-generated',
    )..bindSession(employeeScope);
    await _settleStorage();
    await recovered.redeem(1, retry: true);
    expect(
      repository.redemptions.last.toJson(),
      repository.redemptions.first.toJson(),
    );
    expect(recovered.state.hasUnresolvedRedemption, isFalse);
    await recovered.close();
  });
  for (final status in [401, 403, 408, 429, 400, 409, 418]) {
    test(
      'lost response then $status recovery keeps original intent until canonical success',
      () async {
        final storage = DelayedRedemptionStorage();
        final repository = FakePointsRepository()
          ..redemptionError = const ApiException(
            message: 'response lost',
            kind: FailureKind.network,
          );
        var ids = 0;
        final first = PointsCubit(
          repository,
          intentStorage: storage,
          uuidV4: () => 'key-${++ids}',
        )..bindSession(employeeScope);
        await _settleStorage();
        await first.redeem(1);
        await first.close();
        final recovered = PointsCubit(
          repository,
          intentStorage: storage,
          uuidV4: () => 'key-${++ids}',
        )..bindSession(employeeScope);
        await _settleStorage();
        repository.redemptionError = ApiException(
          message: 'safe recovery failure',
          statusCode: status,
          code: status == 409
              ? 'POINTS_REDEMPTION_CONFLICT'
              : 'UNKNOWN_RESPONSE',
          requestId: 'request-fixture',
        );
        await recovered.redeem(1, retry: true);
        expect(recovered.state.hasUnresolvedRedemption, isTrue);
        expect(recovered.state.partialFailure?.requestId, 'request-fixture');
        await recovered.redeem(2);
        expect(ids, 1);
        repository.redemptionError = null;
        await recovered.redeem(1, retry: true);
        expect(
          repository.redemptions.map((r) => r.clientRedemptionId).toSet(),
          {'key-1'},
        );
        expect(repository.redemptions.map((r) => r.redPoints).toSet(), {1});
        expect(recovered.state.hasUnresolvedRedemption, isFalse);
        await recovered.close();
      },
    );
  }
  test(
    'confirmed insufficient balance is resolved only after durable cleanup',
    () async {
      final storage = DelayedRedemptionStorage()..failClear = true;
      final repository = FakePointsRepository()
        ..redemptionError = const ApiException(
          message: 'not enough green',
          statusCode: 409,
          code: 'POINTS_INSUFFICIENT_GREEN',
          kind: FailureKind.validation,
        );
      final cubit = PointsCubit(
        repository,
        intentStorage: storage,
        uuidV4: () => 'business-key',
      )..bindSession(employeeScope);
      await _settleStorage();
      await cubit.redeem(1);
      expect(cubit.state.hasUnresolvedRedemption, isTrue);
      storage.failClear = false;
      await cubit.redeem(1, retry: true);
      expect(cubit.state.hasUnresolvedRedemption, isFalse);
      expect(repository.redemptions.last.clientRedemptionId, 'business-key');
      await cubit.close();
    },
  );
}
