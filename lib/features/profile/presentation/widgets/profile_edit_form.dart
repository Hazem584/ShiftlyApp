import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_fields_section.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_photo_dialogs.dart';

import 'profile_edit_footer.dart';
import 'profile_edit_photo_actions.dart';
import 'profile_edit_save.dart';

class ProfileEditForm extends StatefulWidget {
  const ProfileEditForm({
    super.key,
    required this.profile,
    required this.action,
    required this.onCancel,
    required this.onSaved,
  });

  final ManagerProfile profile;
  final ProfileAction action;
  final VoidCallback onCancel, onSaved;

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName ?? '');
  late final _email = TextEditingController(text: widget.profile.email ?? '');
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  bool _picking = false;

  bool get _busy => widget.action != ProfileAction.idle || _picking;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    setState(() => _picking = true);
    try {
      await pickProfileEditPhoto(context);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;
    void onSaved() => widget.onSaved();
    await saveProfileEdit(context, _name.text, _phone.text, onSaved);
  }

  Future<void> _photoOptions() async {
    if (_busy) return;
    final act = await showProfilePhotoOptionsSheet(context, widget.profile);
    if (!mounted) return;
    if (act == 'replace') {
      await _pickPhoto();
    } else if (act == 'remove' && !_busy) {
      await deleteProfileEditPhoto(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: CommunicationPage(
      title: 'Edit information',
      onBack: _busy ? () {} : widget.onCancel,
      footer: ProfileEditFooter(
        busy: _busy,
        saving: widget.action == ProfileAction.saving,
        onSave: _save,
        onCancel: widget.onCancel,
      ),
      child: ProfileEditFieldsSection(
        formKey: _formKey,
        profile: widget.profile,
        busy: _busy,
        picking: _picking,
        onPhotoOptions: _photoOptions,
        nameController: _name,
        emailController: _email,
        phoneController: _phone,
      ),
    ),
  );
}
