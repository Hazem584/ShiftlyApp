import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_validation.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_media_review_screen.dart';

const _documentTypeGroup = XTypeGroup(
  label: 'Documents',
  extensions: ['pdf', 'xlsx', 'xls', 'csv', 'txt'],
  uniformTypeIdentifiers: [
    'public.pdf',
    'org.openxmlformats.spreadsheetml.sheet',
    'com.microsoft.excel.xls',
    'public.comma-separated-values-text',
    'public.plain-text',
  ],
);

Future<void> pickChatDocument(ChatMediaCapture capture) async {
  if (capture.mediaBusy) return;
  final context = capture.context;
  final conversation = context.read<ChatConversationCubit>();
  final generation = conversation.generation;
  capture.setMediaBusy(true);
  try {
    final file = await openFile(acceptedTypeGroups: const [_documentTypeGroup]);
    if (file == null ||
        !capture.active ||
        conversation.generation != generation) {
      return;
    }
    if (await file.length() > ChatDocumentValidation.maxBytes) {
      throw const FormatException('Document too large');
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted ||
        !capture.active ||
        conversation.generation != generation) {
      return;
    }
    if (!ChatDocumentValidation.valid(bytes, file.name)) {
      throw const FormatException('Invalid document');
    }
    final decision = await Navigator.push<ChatMediaDecision>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatMediaReviewScreen(
          kind: 'DOCUMENT',
          bytes: bytes,
          fileName: file.name,
        ),
      ),
    );
    if (!capture.active ||
        conversation.generation != generation ||
        decision == null) {
      return;
    }
    if (decision.reselect) {
      capture.setMediaBusy(false);
      await capture.pickDocument();
      return;
    }
    final id = await conversation.sendDocument(bytes, file.name);
    if (id == null) throw StateError('Document not saved');
  } catch (_) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('Choose a PDF, Excel, CSV or text file up to 10 MB.'),
      );
    }
  } finally {
    if (capture.active) capture.setMediaBusy(false);
  }
}
