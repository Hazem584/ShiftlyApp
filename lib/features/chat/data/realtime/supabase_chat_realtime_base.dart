import 'dart:convert';

import 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRealtimeCallbackSubscription implements ChatRealtimeSubscription {
  ChatRealtimeCallbackSubscription(this._dispose);
  final Future<void> Function() _dispose;
  bool _cancelled = false;

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    await _dispose();
  }
}

abstract class SupabaseChatRealtimeBase
    implements ChatLiveRealtime, ChatGroupStateRealtime {
  SupabaseChatRealtimeBase(this.client);
  final SupabaseClient client;
  int sequence = 0;

  String sessionId() {
    try {
      final token = client.auth.currentSession?.accessToken;
      final claims = jsonDecode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(token!.split('.')[1])),
        ),
      ) as Map;
      return claims['session_id'] as String;
    } catch (_) {
      return 'unavailable';
    }
  }
}
