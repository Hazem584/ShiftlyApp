import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/access_screen.dart';

class WorkspaceEntryScreen extends StatefulWidget {
  const WorkspaceEntryScreen({this.join = false, super.key});
  final bool join;

  @override
  State<WorkspaceEntryScreen> createState() => _WorkspaceEntryScreenState();
}

class _WorkspaceEntryScreenState extends State<WorkspaceEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');

  @override
  void dispose() {
    _value.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccessScreen(
    title: widget.join ? 'Join with a token' : 'Create workspace',
    actions: [
      FilledButton(
        key: Key(widget.join ? 'accept-invitation' : 'submit-workspace'),
        onPressed: () {
          if (_form.currentState?.validate() != true) return;
          Navigator.of(
            context,
          ).pop((value: _value.text.trim(), timezone: _timezone.text.trim()));
        },
        child: Text(
          context.tr(widget.join ? 'Accept invitation' : 'Create workspace'),
        ),
      ),
    ],
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.join) ...[
              Text(context.tr('Paste the token shared by your manager.')),
              const SizedBox(height: 20),
            ],
            TextFormField(
              key: Key(
                widget.join ? 'invitation-token-field' : 'workspace-name',
              ),
              controller: _value,
              obscureText: widget.join,
              autocorrect: !widget.join,
              enableSuggestions: !widget.join,
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : context.tr('This field is required'),
              decoration: InputDecoration(
                labelText: context.tr(
                  widget.join ? 'One-time invitation token' : 'Workspace name',
                ),
              ),
            ),
            if (!widget.join) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('workspace-timezone'),
                controller: _timezone,
                decoration: InputDecoration(labelText: context.tr('Timezone')),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        context.tr(
          widget.join
              ? 'Tokens can expire or be used once.'
              : 'Schedules and attendance use this workspace’s timezone.',
        ),
      ),
    ],
  );
}
