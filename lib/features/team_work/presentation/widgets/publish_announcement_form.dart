import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class PublishAnnouncementForm extends StatelessWidget {
  const PublishAnnouncementForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.bodyController,
    required this.acknowledge,
    required this.busy,
    required this.error,
    required this.onAcknowledgeChanged,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController, bodyController;
  final bool acknowledge, busy;
  final String? error;
  final ValueChanged<bool> onAcknowledgeChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 540,
    child: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              enabled: !busy,
              maxLength: 160,
              decoration: InputDecoration(labelText: context.tr('Title')),
              validator: (v) => v?.trim().isNotEmpty == true
                  ? null
                  : context.tr('Please enter a title.'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bodyController,
              enabled: !busy,
              minLines: 4,
              maxLines: 8,
              maxLength: 4000,
              decoration: InputDecoration(
                labelText: context.tr('Announcement'),
              ),
              validator: (v) => v?.trim().isNotEmpty == true
                  ? null
                  : context.tr('Please enter your announcement.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Require acknowledgment')),
              subtitle: Text(
                context.tr(
                  'Each recipient must confirm they have read this announcement.',
                ),
              ),
              value: acknowledge,
              onChanged: busy ? null : onAcknowledgeChanged,
            ),
            if (error != null)
              Text(
                context.tr(error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
