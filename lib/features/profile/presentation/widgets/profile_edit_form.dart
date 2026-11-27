import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_fields_section.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_photo_dialogs.dart';

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
      final image = await context.read<ProfileImagePicker>().pickImage();
      if (!mounted || image == null) return;
      final result = await context.read<ProfileCubit>().uploadAvatar(image);
      if (mounted) showProfileAvatarResult(context, result);
    } catch (_) {
      if (mounted) {
        ToastService.error(context, message: 'Could not open that image.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _deletePhoto() async {
    if (_busy || !await confirmDeleteProfilePhoto(context) || !mounted) return;
    final result = await context.read<ProfileCubit>().deleteAvatar();
    if (!mounted) return;
    if (result == ProfileOperationResult.success) {
      ToastService.success(context, message: 'Profile photo removed');
    } else if (result == ProfileOperationResult.failure) {
      ToastService.error(context, message: profileFailureMessage(context));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;
    final phone = _phone.text.trim();
    final result = await context.read<ProfileCubit>().update(
      fullName: _name.text.trim(),
      phone: phone.isEmpty ? null : phone,
    );
    if (!mounted) return;
    if (result == ProfileOperationResult.success) {
      widget.onSaved();
      ToastService.success(context, message: 'Profile updated successfully');
    } else if (result == ProfileOperationResult.failure) {
      ToastService.error(context, message: profileFailureMessage(context));
    }
  }

  Future<void> _photoOptions() async {
    if (_busy) return;
    final act = await showProfilePhotoOptionsSheet(context, widget.profile);
    if (!mounted) return;
    if (act == 'replace') await _pickPhoto();
    if (act == 'remove') await _deletePhoto();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: CommunicationPage(
      title: 'Edit information',
      onBack: _busy ? () {} : widget.onCancel,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('save-profile'),
            onPressed: _busy ? null : _save,
            child: Text(
              context.tr(
                widget.action == ProfileAction.saving
                    ? 'Saving…'
                    : 'Save changes',
              ),
            ),
          ),
          TextButton(
            key: const Key('cancel-profile-edit'),
            onPressed: _busy ? null : widget.onCancel,
            child: Text(context.tr('Cancel')),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          key: const Key('profile-edit-content'),
          padding: const EdgeInsets.all(24),
          children: buildProfileEditFormContent(
            context,
            profile: widget.profile,
            busy: _busy,
            picking: _picking,
            onPhotoOptions: _photoOptions,
            nameController: _name,
            emailController: _email,
            phoneController: _phone,
          ),
        ),
      ),
    ),
  );
}
