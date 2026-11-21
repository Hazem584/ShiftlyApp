import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/data/stream/stream_chat_mapper.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sdk;

const groupId = '33333333-3333-4333-8333-333333333333';
const memberId = '44444444-4444-4444-8444-444444444444';
ChatMessage legacy(DateTime at) => ChatMessage(
  id: '55555555-5555-4555-8555-555555555555',
  groupId: groupId,
  type: 'TEXT',
  text: 'Latest saved message',
  sender: const ChatSender(membershipId: memberId),
  createdAt: at,
);
ChatGroup base(ChatMessage? last) => ChatGroup(
  id: groupId,
  workspaceId: 'workspace',
  name: 'Instock',
  memberCount: 2,
  unreadCount: 0,
  createdAt: DateTime.utc(2026),
  updatedAt: last?.createdAt ?? DateTime.utc(2026),
  lastMessage: last,
);
sdk.Message incoming(DateTime at) => sdk.Message(
  id: '66666666-6666-4666-8666-666666666666',
  text: 'Latest Stream message',
  user: sdk.User(id: memberId),
  createdAt: at,
);
void main() {
  test('older watched Stream state cannot replace newer saved preview or timestamp', () {
    final saved = legacy(DateTime.utc(2026, 11, 20, 18, 57));
    final mapped = StreamChatMapper.group(
      base(saved),
      _Channel([incoming(DateTime.utc(2026, 11, 20))]),
    );
    expect(mapped.lastMessage, saved);
    expect(mapped.updatedAt, saved.createdAt);
  });
  test(
    'latest Stream message supplies inbox preview and its actual timestamp',
    () {
      final at = DateTime.utc(2026, 11, 20, 18, 57);
      final mapped = StreamChatMapper.group(
        base(legacy(DateTime.utc(2026, 11, 19))),
        _Channel([incoming(at)]),
      );
      expect(mapped.lastMessage?.text, 'Latest Stream message');
      expect(mapped.lastMessage?.createdAt, at);
    },
  );
  test('empty watched channel preserves existing preview', () {
    final saved = legacy(DateTime.utc(2026, 11, 20, 18, 57));
    expect(
      StreamChatMapper.group(base(saved), _Channel([])).lastMessage,
      saved,
    );
  });
}

class _Channel implements sdk.Channel {
  _Channel(this.messages);
  final List<sdk.Message> messages;
  @override
  sdk.ChannelClientState get state => _State(messages);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _State implements sdk.ChannelClientState {
  _State(this.messages);
  @override
  final List<sdk.Message> messages;
  @override
  List<sdk.Read> get read => [];
  @override
  int get unreadCount => 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
