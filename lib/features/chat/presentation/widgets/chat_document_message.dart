import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_document_controller.dart';

import 'chat_document_message_state.dart';

class ChatDocumentMessage extends StatefulWidget {
  const ChatDocumentMessage({
    required this.message,
    required this.repository,
    required this.workspaceId,
    this.controller,
    super.key,
  });
  final ChatMessage message;
  final ChatRepository repository;
  final String workspaceId;
  final ChatDocumentController? controller;
  @override
  State<ChatDocumentMessage> createState() => ChatDocumentMessageState();
}
