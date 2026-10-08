import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/data/memory_manager_intent_storage.dart';

class DelayedManagerStorage extends MemoryManagerIntentStorage {
  Completer<void>? writeGate;
  bool failWrite = false, failClear = false;
  @override
  Future<void> write(FeatureSessionScope scope, String value) async {
    await writeGate?.future;
    if (failWrite) {
      throw StateError('Storage failed');
    }
    await super.write(scope, value);
  }

  @override
  Future<void> clear(FeatureSessionScope scope, String value) async {
    if (failClear) {
      throw StateError('Cleanup failed');
    }
    await super.clear(scope, value);
  }
}
