import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import 'chat_document_content.dart';
import 'chat_voice_review.dart';

class ChatMediaReviewContent extends StatelessWidget {
  const ChatMediaReviewContent({
    required this.kind,
    required this.caption,
    this.bytes,
    this.fileName,
    this.voicePath,
    this.durationMs,
    this.location,
    super.key,
  });

  final String kind;
  final TextEditingController caption;
  final Uint8List? bytes;
  final String? fileName, voicePath;
  final int? durationMs;
  final ChatLocation? location;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      if (kind == 'IMAGE')
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(bytes!, height: 340, fit: BoxFit.contain),
        ),
      if (kind == 'DOCUMENT') ...[
        EmployeeTile(
          icon: Icons.description_outlined,
          title: fileName!,
          subtitle: '${(bytes!.length / 1024).toStringAsFixed(1)} KB',
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 380,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ChatDocumentContent(
              bytes: bytes!,
              fileName: fileName!,
              sourceId: 'local-preview',
            ),
          ),
        ),
      ],
      if (kind == 'VOICE')
        ChatVoiceReview(voicePath: voicePath, durationMs: durationMs),
      if (location case final location?) ...[
        EmployeeTile(
          icon: Icons.location_on_outlined,
          title: context.tr('Check this location before sending.'),
          subtitle:
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(
            'The location is a single point shared in this conversation.',
          ),
        ),
      ],
      if (kind == 'IMAGE' || kind == 'LOCATION') ...[
        const SizedBox(height: 24),
        TextField(
          key: const Key('chat-media-caption'),
          controller: caption,
          maxLength: kind == 'LOCATION' ? 120 : 1000,
          maxLines: kind == 'LOCATION' ? 1 : 3,
          decoration: InputDecoration(
            labelText: context.tr(
              kind == 'IMAGE'
                  ? 'Caption · Optional'
                  : 'Location name · Optional',
            ),
          ),
        ),
      ],
    ],
  );
}
