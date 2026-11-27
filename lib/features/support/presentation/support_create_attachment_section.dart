import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

class SupportCreateAttachmentSection extends StatelessWidget {
  const SupportCreateAttachmentSection({
    required this.image,
    required this.saving,
    required this.savedId,
    required this.error,
    required this.onPick,
    required this.onRemoveImage,
    required this.onSave,
    required this.onOpenSaved,
    super.key,
  });
  final ProfileImageSelection? image;
  final bool saving;
  final String? savedId, error;
  final VoidCallback onPick, onRemoveImage, onSave, onOpenSaved;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (image != null) ...[
        Image.memory(image!.bytes, height: 220, fit: BoxFit.contain),
        TextButton(
          onPressed: saving ? null : onRemoveImage,
          child: Text(context.tr('Remove image')),
        ),
      ],
      OutlinedButton.icon(
        onPressed: saving || savedId != null ? null : onPick,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(context.tr('Attach an image (optional)')),
      ),
      Text(
        context.tr(
          'Only you and authorized support staff can view your report and image.',
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            context.tr(error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      FilledButton(
        onPressed: saving ? null : onSave,
        child: Text(
          context.tr(
            saving
                ? 'Sending…'
                : savedId != null
                ? 'Retry image upload'
                : 'Send report',
          ),
        ),
      ),
      if (savedId != null)
        TextButton(
          onPressed: onOpenSaved,
          child: Text(context.tr('Open saved report')),
        ),
    ],
  );
}
