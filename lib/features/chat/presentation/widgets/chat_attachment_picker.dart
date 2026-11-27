import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

Future<int?> _pickChatAttachment(
  BuildContext context, {
  required bool includeDocument,
}) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  builder: (c) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(c.tr('Share with the group')),
          subtitle: Text(c.tr('Choose an attachment.')),
        ),
        for (final (value, label, subtitle, icon) in [
          (0, 'Photos', 'Choose an image', Icons.image_outlined),
          (1, 'Voice message', 'Record audio', Icons.mic_none),
          (2, 'Location', 'Share a location', Icons.location_on_outlined),
          if (includeDocument)
            (
              3,
              'Document',
              'PDF, Excel, CSV or text',
              Icons.description_outlined,
            ),
        ])
          ListTile(
            leading: Icon(icon),
            title: Text(c.tr(label)),
            subtitle: Text(c.tr(subtitle)),
            onTap: () => Navigator.pop(c, value),
          ),
      ],
    ),
  ),
);

Future<void> showChatAttachmentPicker(
  BuildContext context, {
  required Future<void> Function() onPickImage,
  required Future<void> Function() onStartRecording,
  required Future<void> Function() onShareLocation,
  Future<void> Function()? onPickDocument,
}) async {
  final choice = await _pickChatAttachment(
    context,
    includeDocument: onPickDocument != null,
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 0:
      await onPickImage();
    case 1:
      await onStartRecording();
    case 2:
      await onShareLocation();
    case 3:
      await onPickDocument?.call();
  }
}
