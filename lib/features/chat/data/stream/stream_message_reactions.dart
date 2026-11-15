import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_message_identity.dart';

List<ChatReaction> mapStreamReactions(stream.Message source) => [
  for (final reaction in source.latestReactions ?? <stream.Reaction>[])
    if (ChatReaction.choices.contains(reaction.type) &&
        streamUuid.hasMatch(reaction.userId ?? reaction.user?.id ?? ''))
      ChatReaction(
        emoji: reaction.type,
        membershipId: reaction.userId ?? reaction.user!.id,
      ),
];
