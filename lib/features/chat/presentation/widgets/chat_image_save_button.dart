import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatImageSaveButton extends StatefulWidget {
  const ChatImageSaveButton({required this.saveImage, super.key});

  final Future<void> Function() saveImage;

  @override
  State<ChatImageSaveButton> createState() => _ChatImageSaveButtonState();
}

class _ChatImageSaveButtonState extends State<ChatImageSaveButton> {
  bool _saving = false;
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.saveImage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                kIsWeb ? 'Image downloaded.' : 'Image saved to photos.',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PlatformException &&
                      error.code == 'PHOTO_PERMISSION_DENIED'
                  ? context.tr(
                      'Allow photo access in your phone settings to save images.',
                    )
                  : context.tr(
                      'Could not save this image. Check your connection and try again.',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('save-chat-image'),
    tooltip: context.tr(kIsWeb ? 'Download image' : 'Save to photos'),
    onPressed: _saving ? null : _save,
    icon: _saving
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.download_rounded),
  );
}
