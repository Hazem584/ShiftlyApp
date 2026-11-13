import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';

class ChatRecordingScreen extends StatefulWidget {
  const ChatRecordingScreen({required this.capture, super.key});
  final ChatMediaCapture capture;
  @override
  State<ChatRecordingScreen> createState() => _ChatRecordingScreenState();
}

class _ChatRecordingScreenState extends State<ChatRecordingScreen> {
  bool _finishing = false, _allowPop = false;
  Future<void> _finish(bool send) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.capture.finishRecording(send: send);
    if (!mounted) return;
    setState(() => _finishing = false);
    if (!widget.capture.recording) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => CollaborationSessionBoundary(
    child: CollaborationAppearance(
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _finish(false);
        },
        child: ListenableBuilder(
          listenable: widget.capture,
          builder: (context, _) => EmployeePage(
            title: 'Record voice',
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _finishing ? null : () => _finish(true),
                  child: Text(
                    context.tr(
                      widget.capture.recording ? 'Finish recording' : 'Done',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _finishing ? null : () => _finish(false),
                  child: Text(context.tr('Cancel recording')),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_none,
                  size: 88,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.capture.recordingLabel(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    widget.capture.recording
                        ? 'Recording your voice'
                        : 'Recording finished',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
