import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';
import 'support_create_actions.dart';
import 'support_create_attachment_section.dart';
import 'support_create_fields.dart';

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
    widget.repository
        .contexts(widget.workspaceId)
        .then(
          (v) => mounted ? setState(() => _contexts = v) : null,
          onError: (Object e) =>
              mounted ? setState(() => _error = supportContextError(e)) : null,
        );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await pickSupportAttachment(widget.picker);
    if (mounted && res != null) {
      setState(() => res.$2 != null ? _error = res.$2 : _image = res.$1);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => (_saving = true, _error = null));
    try {
      final id = await submitSupportTicket(
        repository: widget.repository,
        workspaceId: widget.workspaceId,
        clientId: _clientId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        related: _related,
        image: _image,
        existingId: _savedId,
        onTicketCreated: (id) => _savedId = id,
      );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) setState(() => _error = supportSubmitError(e, _savedId));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => CommunicationAppearance(
    child: Builder(
      builder: (c) => Scaffold(
        appBar: AppBar(title: Text(c.tr('Report a problem'))),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SupportCreateFields(
                titleController: _title,
                descriptionController: _description,
                contexts: _contexts,
                editable: !_saving && _savedId == null,
                onRelatedChanged: (v) => setState(() => _related = v),
              ),
              const SizedBox(height: 12),
              SupportCreateAttachmentSection(
                image: _image,
                saving: _saving,
                savedId: _savedId,
                error: _error,
                onPick: _pick,
                onRemoveImage: () => setState(() => _image = null),
                onSave: _save,
                onOpenSaved: () => Navigator.pop(c, _savedId),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
