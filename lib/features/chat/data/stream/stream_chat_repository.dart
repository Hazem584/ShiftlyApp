import 'repository/stream_add_members.dart';
import 'repository/stream_archive_group.dart';
import 'repository/stream_cancel_upload.dart';
import 'repository/stream_create_group.dart';
import 'repository/stream_finalize_upload.dart';
import 'repository/stream_get_group.dart';
import 'repository/stream_initiate_upload.dart';
import 'repository/stream_list_groups.dart';
import 'repository/stream_list_messages.dart';
import 'repository/stream_mark_read.dart';
import 'repository/stream_media_url.dart';
import 'repository/stream_pin_message.dart';
import 'repository/stream_reconcile_messages.dart';
import 'repository/stream_remove_member.dart';
import 'repository/stream_search_messages.dart';
import 'repository/stream_send_location.dart';
import 'repository/stream_send_message.dart';
import 'repository/stream_set_reaction.dart';
import 'repository/stream_unread_count.dart';
import 'repository/stream_update_group.dart';
import 'repository/stream_upload_signed.dart';
import 'stream_chat_repository_base.dart';

class StreamChatRepository extends StreamChatRepositoryBase
    with
        StreamListGroups,
        StreamGetGroup,
        StreamCreateGroup,
        StreamUpdateGroup,
        StreamArchiveGroup,
        StreamAddMembers,
        StreamRemoveMember,
        StreamListMessages,
        StreamSendMessage,
        StreamInitiateUpload,
        StreamUploadSigned,
        StreamFinalizeUpload,
        StreamCancelUpload,
        StreamSendLocation,
        StreamMediaUrl,
        StreamSetReaction,
        StreamReconcileMessages,
        StreamMarkRead,
        StreamUnreadCount,
        StreamSearchMessages,
        StreamPinMessage {
  StreamChatRepository(super.legacy, super.connection);
}
