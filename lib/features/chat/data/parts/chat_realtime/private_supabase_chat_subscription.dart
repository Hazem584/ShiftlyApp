part of '../../chat_realtime.dart';

class _SupabaseChatSubscription implements ChatRealtimeSubscription {
  _SupabaseChatSubscription(this._client, this._channel);
  final SupabaseClient _client;
  final RealtimeChannel _channel;
  bool _cancelled = false;

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    await _client.removeChannel(_channel);
  }
}
