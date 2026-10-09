import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/points/data/redemption_intent_storage.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';

class DelayedRedemptionStorage extends MemoryRedemptionIntentStorage {
  Completer<void>? readGate;
  Completer<void>? writeGate;
  final writeStarted = Completer<void>();
  bool failWrite = false;
  bool failClear = false;
  @override
  Future<RedemptionIntent?> read(FeatureSessionScope scope) async {
    await readGate?.future;
    return super.read(scope);
  }

  @override
  Future<void> write(FeatureSessionScope scope, RedemptionIntent intent) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await writeGate?.future;
    if (failWrite) throw StateError('storage fixture');
    await super.write(scope, intent);
  }

  @override
  Future<void> clear(
    FeatureSessionScope scope,
    String clientRedemptionId,
  ) async {
    if (failClear) throw StateError('cleanup fixture');
    await super.clear(scope, clientRedemptionId);
  }
}
