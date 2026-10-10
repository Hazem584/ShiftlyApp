import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/core/widgets/local_media_image.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_full_screen_image.dart';

class ChatRemoteImage extends StatefulWidget {
  const ChatRemoteImage({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.message,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;

  @override
  State<ChatRemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<ChatRemoteImage> {
  late Future<Object> _media;
  ChatLocalFile? _pinned;
  ChatMediaStore? _cache;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    final groups = context.read<ChatGroupsCubit>();
    final cache = groups.mediaCache;
    _cache = cache;
    final scope = groups.scope;
    if (cache != null && scope != null) {
      _media = cache
          .resolve(
            ChatCacheScope.fromSession(scope, widget.message.groupId),
            widget.message,
            widget.repository,
          )
          .then((file) {
            if (mounted) {
              if (_pinned case final former?) cache.unpin(former);
              _pinned = file;
              cache.pin(file);
            }
            return file;
          });
      return;
    }
    _media = widget.repository.mediaUrl(
      widget.workspaceId,
      widget.message.groupId,
      widget.message.id,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
    future: _media,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SizedBox(
          width: 220,
          height: 140,
          child: Center(
            child: TextButton.icon(
              onPressed: () => setState(_resolve),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retry image')),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          width: 220,
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final media = snapshot.data!;
      final file = media is ChatLocalFile ? media : null;
      final url = media is ChatMediaUrl ? media.url : null;
      final heroTag = 'chat-image-${widget.message.id}';
      return InkWell(
        onTap: () async {
          final groups = context.read<ChatGroupsCubit>();
          final cache = groups.mediaCache;
          final session = groups.scope;
          if (file != null) cache?.pin(file);
          try {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatFullScreenImage(
                  url: url,
                  file: file,
                  heroTag: heroTag,
                  saveImage: session == null || groups.gallery == null
                      ? null
                      : () => groups.gallery!.save(
                          message: widget.message,
                          repository: widget.repository,
                          session: session,
                          cache: cache,
                          hasAccess: () =>
                              mounted &&
                              groups.scope == session &&
                              !context
                                  .read<ChatConversationCubit>()
                                  .state
                                  .accessLost,
                        ),
                  cache: cache,
                  scope: session == null
                      ? null
                      : ChatCacheScope.fromSession(
                          session,
                          widget.message.groupId,
                        ),
                ),
              ),
            );
          } finally {
            if (file != null) cache?.unpin(file);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
              child: file != null
                  ? LocalMediaImage(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 960,
                      errorBuilder: (_, _, _) => TextButton(
                        onPressed: () => setState(_resolve),
                        child: Text(context.tr('Retry image')),
                      ),
                    )
                  : Image.network(
                      url!.toString(),
                      fit: BoxFit.cover,
                      cacheWidth: 960,
                      errorBuilder: (_, _, _) => SizedBox(
                        width: 220,
                        height: 140,
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => setState(_resolve),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('Retry image')),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  );
  @override
  void dispose() {
    final file = _pinned;
    if (file != null) _cache?.unpin(file);
    super.dispose();
  }
}
