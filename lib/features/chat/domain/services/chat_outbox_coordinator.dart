import 'dart:async';

/// One ordered text lane and one media lane, shared across conversations.
/// A slow upload cannot hold text delivery; total concurrency stays bounded.
class ChatOutboxCoordinator {
  final _media = _DeliveryLane();
  final _text = _DeliveryLane();
  Future<void> acquire({bool lightweight = false}) =>
      (lightweight ? _text : _media).acquire();
  void release({bool lightweight = false}) =>
      (lightweight ? _text : _media).release();
}

class _DeliveryLane {
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
