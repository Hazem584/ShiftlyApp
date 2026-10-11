import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_message_uuid.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class PublishAnnouncementDialog extends StatefulWidget {
  const PublishAnnouncementDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
  });
  final TeamWorkRepository repository;
  final String workspaceId;
  @override
  State<PublishAnnouncementDialog> createState() =>
      _PublishAnnouncementDialogState();
}

class _PublishAnnouncementDialogState extends State<PublishAnnouncementDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(), _body = TextEditingController();
  final _clientId = chatMessageUuid();
  bool _acknowledge = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.publish(
        widget.workspaceId,
        clientId: _clientId,
        title: _title.text,
        body: _body.text,
        acknowledgment: _acknowledge,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ApiErrorParser.parse(error).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(context.tr('Publish team announcement')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 160,
                  decoration: InputDecoration(labelText: context.tr('Title')),
                  validator: (v) => v?.trim().isNotEmpty == true
                      ? null
                      : context.tr('Please enter a title.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  enabled: !_busy,
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
                  value: _acknowledge,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _acknowledge = v),
                ),
                if (_error != null)
                  Text(
                    context.tr(_error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _busy ? null : _publish,
          child: Text(context.tr(_busy ? 'Saving…' : 'Publish')),
        ),
      ],
    ),
  );
}
