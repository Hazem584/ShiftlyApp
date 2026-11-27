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
  Widget build(BuildContext context) {
    final join = widget.join;
    return AccessScreen(
      title: join ? 'Join with a token' : 'Create workspace',
      actions: [
        FilledButton(
          key: Key(join ? 'accept-invitation' : 'submit-workspace'),
          onPressed: () {
            if (_form.currentState?.validate() != true) return;
            Navigator.of(
              context,
            ).pop((value: _value.text.trim(), timezone: _timezone.text.trim()));
          },
          child: Text(
            context.tr(join ? 'Accept invitation' : 'Create workspace'),
          ),
        ),
      ],
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (join) ...[
                Text(context.tr('Paste the token shared by your manager.')),
                const SizedBox(height: 20),
              ],
              TextFormField(
                key: Key(join ? 'invitation-token-field' : 'workspace-name'),
                controller: _value,
                obscureText: join,
                autocorrect: !join,
                enableSuggestions: !join,
                validator: (v) => v?.trim().isNotEmpty == true
                    ? null
                    : context.tr('This field is required'),
                decoration: InputDecoration(
                  labelText: context.tr(
                    join ? 'One-time invitation token' : 'Workspace name',
                  ),
                ),
              ),
              if (!join) ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('workspace-timezone'),
                  controller: _timezone,
                  decoration: InputDecoration(
                    labelText: context.tr('Timezone'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(
            join
                ? 'Tokens can expire or be used once.'
                : 'Schedules and attendance use this workspace’s timezone.',
          ),
        ),
      ],
    );
  }
}
