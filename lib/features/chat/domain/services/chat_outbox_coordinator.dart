import 'dart:async';

class ChatOutboxCoordinator {
  final List<Completer<void>> _waiting = [];
  bool _active = false;
  Future<void> acquire() async {
    if (!_active) {
      _active = true;
      return;
    }
    final waiter = Completer<void>();
    _waiting.add(waiter);
    await waiter.future;
  }

  void release() {
    if (_waiting.isEmpty) {
      _active = false;
    } else {
      _waiting.removeAt(0).complete();
    }
  }
}
