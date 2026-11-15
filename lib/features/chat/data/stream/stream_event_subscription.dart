import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

class StreamEventSubscription implements ChatRealtimeSubscription {
  StreamEventSubscription(this.stop);
  final Future<void> Function() stop;
  @override
  Future<void> cancel() => stop();
}
