import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatRecordingControls extends StatelessWidget {
  const ChatRecordingControls({
    required this.recordingLabel,
    required this.onFinishRecording,
    super.key,
  });

  final String recordingLabel;
  final Future<void> Function({required bool send}) onFinishRecording;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: context.tr('Cancel recording'),
        onPressed: () => onFinishRecording(send: false),
        icon: const Icon(Icons.delete_outline),
      ),
      const Icon(Icons.mic, color: Colors.red),
      const SizedBox(width: 8),
      Expanded(child: Text(recordingLabel)),
      FilledButton.icon(
        onPressed: () => onFinishRecording(send: true),
        icon: const Icon(Icons.send),
        label: Text(context.tr('Finish recording')),
      ),
    ],
  );
}
