part of '../../mock_chat_repository.dart';

class _NoopSubscription implements ChatRealtimeSubscription {
  const _NoopSubscription();
  @override
  Future<void> cancel() async {}
}
