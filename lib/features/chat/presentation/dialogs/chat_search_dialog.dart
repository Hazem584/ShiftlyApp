import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_reply_preview.dart';

class ChatSearchDialog extends StatefulWidget {
  const ChatSearchDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.groupId,
    required this.timezone,
    this.pinned = false,
  });
  final ChatRepository repository;
  final String workspaceId, groupId, timezone;
  final bool pinned;
  @override
  State<ChatSearchDialog> createState() => _ChatSearchDialogState();
}

class _ChatSearchDialogState extends State<ChatSearchDialog> {
  final _query = TextEditingController();
  List<ChatMessage> _messages = [];
  String? _cursor, _error;
  bool _loading = false, _hasMore = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    if (widget.pinned) _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search({bool more = false}) async {
    final text = _query.text.trim();
    if (!widget.pinned && text.isEmpty) return;
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _messages = [];
        _cursor = null;
      }
    });
    try {
      final page = await widget.repository.searchMessages(
        widget.workspaceId,
        widget.groupId,
        query: text.isEmpty ? null : text,
        pinned: widget.pinned,
        cursor: more ? _cursor : null,
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _messages = [..._messages, ...page.messages];
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _loading = false;
      });
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() {
          _loading = false;
          _error = ApiErrorParser.parse(error).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.tr(widget.pinned ? 'Pinned messages' : 'Search conversation'),
    ),
    content: SizedBox(
      width: 620,
      height: 440,
      child: Column(
        children: [
          TextField(
            controller: _query,
            maxLength: 120,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: context.tr('Search messages'),
              suffixIcon: IconButton(
                onPressed: () => _search(),
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              context.tr(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Expanded(
            child: ListView(
              children: [
                if (!_loading && _messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.tr(
                        widget.pinned ? 'No pinned messages yet.' : 'Search the full conversation, including older messages.',
                      ),
                    ),
                  ),
                for (final message in _messages)
                  ListTile(
                    title: Text(message.sender.displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(replyMessageText(message)),
                        Text(
                          WorkspaceTime.dateTime(
                            message.createdAt,
                            widget.timezone,
                            locale: Localizations.localeOf(context).toString(),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: context.tr('Reply'),
                      onPressed: () => Navigator.pop(context, message),
                      icon: const Icon(Icons.reply),
                    ),
                  ),
                if (_hasMore)
                  TextButton(
                    onPressed: _loading ? null : () => _search(more: true),
                    child: Text(context.tr('Load more')),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Close')),
      ),
    ],
  );
}
