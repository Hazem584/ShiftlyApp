import 'dart:async';

import 'package:shiftly/features/onboarding/data/onboarding_storage.dart';

class OnboardingTestStorage implements OnboardingStorage {
  bool completed = false, failRead = false, failWrite = false;
  int writes = 0;
  Completer<bool>? readGate;
  Completer<void>? writeGate;
  @override
  Future<bool> readCompleted() async {
    if (failRead) {
      throw StateError('read failed');
    }
    if (readGate case final gate?) {
      return gate.future;
    }
    return completed;
  }

  @override
  Future<void> complete() async {
    writes++;
    if (writeGate != null) {
      await writeGate!.future;
    }
    if (failWrite) {
      throw StateError('write failed');
    }
    completed = true;
  }
}
