import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';

class SupportCreateScreen extends StatefulWidget {
  const SupportCreateScreen({
    required this.repository,
    required this.workspaceId,
    required this.picker,
    super.key,
  });
  final SupportRepository repository;
  final String workspaceId;
  final ProfileImagePicker picker;
  @override
  State<SupportCreateScreen> createState() => _SupportCreateScreenState();
}

class _SupportCreateScreenState extends State<SupportCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _clientId = const Uuid().v4();
  List<SupportContext> _contexts = [];
  SupportContext? _related;
  ProfileImageSelection? _image;
  String? _savedId, _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _loadContexts();
  }

  Future<void> _loadContexts() async {
    try {
      final values = await widget.repository.contexts(widget.workspaceId);
      if (mounted) setState(() => _contexts = values);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException ? e.message : 'Could not load task and shift choices. You can still report a general problem.',
        );
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await widget.picker.pickImage();
      if (!mounted || image == null) return;
      if (image.bytes.length > 2097152 || image.detectedMimeType == null) {
        setState(() => _error = 'Choose a JPEG, PNG or WebP image up to 2 MB.');
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not select an image.');
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_savedId == null) {
        final ticket = await widget.repository.create(
          workspaceId: widget.workspaceId,
          clientId: _clientId,
          title: _title.text.trim(),
          description: _description.text.trim(),
          related: _related,
        );
        _savedId = ticket.id;
      }
      final image = _image;
      if (image != null) {
        await widget.repository.uploadImage(
          id: _savedId!,
          bytes: image.bytes,
          mime: image.detectedMimeType!,
        );
      }
      if (mounted) Navigator.pop(context, _savedId);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = _savedId != null
              ? 'Your report was saved, but its image was not uploaded. Retry or open the saved report.'
              : e is ApiException
              ? e.message
              : 'Could not submit the support report. Retry safely.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      CommunicationAppearance(child: Builder(builder: _build));
  Widget _build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Report a problem'))),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextFormField(
            controller: _title,
            enabled: !_saving && _savedId == null,
            maxLength: 120,
            decoration: InputDecoration(labelText: context.tr('Problem title')),
            validator: (v) => (v?.trim().length ?? 0) < 3
                ? context.tr('Enter a title of at least 3 characters.')
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SupportContext?>(
            initialValue: null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Related task or shift (optional)'),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(context.tr('General problem')),
              ),
              ..._contexts.map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    v.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _saving || _savedId != null
                ? null
                : (v) => setState(() => _related = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            enabled: !_saving && _savedId == null,
            minLines: 5,
            maxLines: 10,
            maxLength: 5000,
            decoration: InputDecoration(
              labelText: context.tr('Describe what happened'),
            ),
            validator: (v) => (v?.trim().length ?? 0) < 10
                ? context.tr('Describe the problem in at least 10 characters.')
                : null,
          ),
          const SizedBox(height: 12),
          if (_image != null) ...[
            Image.memory(_image!.bytes, height: 220, fit: BoxFit.contain),
            TextButton(
              onPressed: _saving ? null : () => setState(() => _image = null),
              child: Text(context.tr('Remove image')),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _saving || _savedId != null ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(context.tr('Attach an image (optional)')),
          ),
          Text(
            context.tr(
              'Only you and authorized support staff can view your report and image.',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.tr(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              context.tr(
                _saving
                    ? 'Sending…'
                    : _savedId != null
                    ? 'Retry image upload'
                    : 'Send report',
              ),
            ),
          ),
          if (_savedId != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _savedId),
              child: Text(context.tr('Open saved report')),
            ),
        ],
      ),
    ),
  );
}
