import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_media_review_content.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_media_review_footer.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';

class ChatMediaDecision {
  const ChatMediaDecision({this.caption, this.reselect = false});
  final String? caption;
  final bool reselect;
}

class ChatMediaReviewScreen extends StatefulWidget {
  const ChatMediaReviewScreen({
    required this.kind,
    this.bytes,
    this.fileName,
    this.voicePath,
    this.durationMs,
    this.location,
    super.key,
  });
  final String kind;
  final Uint8List? bytes;
  final String? fileName, voicePath;
  final int? durationMs;
  final ChatLocation? location;
  @override
  State<ChatMediaReviewScreen> createState() => _ChatMediaReviewScreenState();
}

class _ChatMediaReviewScreenState extends State<ChatMediaReviewScreen> {
  final _caption = TextEditingController();
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CollaborationSessionBoundary(child: Builder(builder: _build));
  Widget _build(BuildContext context) => CollaborationAppearance(
    child: Builder(
      builder: (context) {
        final title = switch (widget.kind) {
          'IMAGE' => 'Image before sending',
          'VOICE' => 'Voice preview',
          'LOCATION' => 'Confirm location',
          _ => 'Document preview',
        };
        final action = switch (widget.kind) {
          'IMAGE' => 'Send image',
          'VOICE' => 'Send voice message',
          'LOCATION' => 'Send location',
          _ => 'Send document',
        };
        return EmployeePage(
          title: title,
          footer: ChatMediaReviewFooter(
            kind: widget.kind,
            action: action,
            onConfirm: () => Navigator.pop(
              context,
              ChatMediaDecision(caption: _caption.text.trim()),
            ),
            onCancel: () => Navigator.pop(
              context,
              widget.kind == 'IMAGE' || widget.kind == 'DOCUMENT'
                  ? const ChatMediaDecision(reselect: true)
                  : null,
            ),
          ),
          child: ChatMediaReviewContent(
            kind: widget.kind,
            caption: _caption,
            bytes: widget.bytes,
            fileName: widget.fileName,
            voicePath: widget.voicePath,
            durationMs: widget.durationMs,
            location: widget.location,
          ),
        );
      },
    ),
  );
}
