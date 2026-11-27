import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ProfileEditFooter extends StatelessWidget {
  const ProfileEditFooter({
    required this.busy,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final bool busy, saving;
  final VoidCallback onSave, onCancel;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        key: const Key('save-profile'),
        onPressed: busy ? null : onSave,
        child: Text(context.tr(saving ? 'Saving…' : 'Save changes')),
      ),
      TextButton(
        key: const Key('cancel-profile-edit'),
        onPressed: busy ? null : onCancel,
        child: Text(context.tr('Cancel')),
      ),
    ],
  );
}
