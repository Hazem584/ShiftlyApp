part of '../../chat_screen.dart';

class PendingMediaBubble extends StatelessWidget {
  const PendingMediaBubble({
    required this.pending,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });
  final PendingChatMessage pending;
  final Future<void> Function(String) onRetry;
  final Future<void> Function(String) onCancel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.mediaType == PendingChatMediaType.image)
            if (pending.previewBytes != null)
              Image.memory(
                pending.previewBytes!,
                height: 160,
                width: 260,
                cacheWidth: 720,
                fit: BoxFit.cover,
              )
            else
              const Row(
                children: [
                  Icon(Icons.image_outlined),
                  SizedBox(width: 8),
                  Text('Image'),
                ],
              )
          else
            Row(
              children: [
                const Icon(Icons.mic),
                const SizedBox(width: 8),
                const Text('Voice message'),
                if (pending.durationMs != null) ...[
                  const SizedBox(width: 8),
                  Text(_durationLabel(pending.durationMs!)),
                ],
              ],
            ),
          const SizedBox(height: 8),
          if (pending.status != ChatUploadState.failed)
            LinearProgressIndicator(
              value: pending.status == ChatUploadState.preparing
                  ? null
                  : pending.progress.clamp(0, 1),
            ),
          Text(switch (pending.status) {
            ChatUploadState.preparing => 'Preparing…',
            ChatUploadState.uploading => 'Uploading…',
            ChatUploadState.finalizing => 'Sending…',
            ChatUploadState.sent => 'Sent',
            ChatUploadState.failed =>
              pending.failure?.message ?? 'Upload failed',
            ChatUploadState.cancelled => 'Cancelled',
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (pending.status == ChatUploadState.failed)
                TextButton(
                  onPressed: () => onRetry(pending.clientMessageId),
                  child: const Text('Retry'),
                ),
              TextButton(
                onPressed: () => onCancel(pending.clientMessageId),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _durationLabel(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
