import 'package:shiftly/features/chat/data/realtime/supabase_chat_broadcast_realtime.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_group_realtime.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_inbox_realtime.dart';
import 'package:shiftly/features/chat/data/realtime/supabase_chat_realtime_base.dart';

export 'package:shiftly/features/chat/domain/repositories/chat_realtime.dart';

class SupabaseChatRealtime extends SupabaseChatRealtimeBase
    with
        SupabaseChatGroupRealtime,
        SupabaseChatInboxRealtime,
        SupabaseChatBroadcastRealtime {
  SupabaseChatRealtime(super.client);
}
