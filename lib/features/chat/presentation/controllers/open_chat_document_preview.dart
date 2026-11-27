import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_attachment.dart';

import '../screens/chat_document_preview_screen.dart';

Future<void> openChatDocumentPreview(
  BuildContext context, {
  required Uint8List bytes,
  required String messageId,
  required ChatAttachment attachment,
  required FeatureSessionScope session,
  required Stream<int>? accessChanges,
  required bool Function() hasAccess,
  required Future<bool> Function() onDownload,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatDocumentPreviewScreen(
        bytes: bytes,
        fileName: attachment.fileName ?? context.tr('Document'),
        sourceId: '${session.userId}:$messageId:${attachment.id}',
        accessChanges: accessChanges,
        hasAccess: hasAccess,
        onDownload: () async {
          if (!hasAccess()) {
            throw StateError('Chat access unavailable');
          }
          return onDownload();
        },
      ),
    ),
  );
}
