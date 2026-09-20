import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileEditForm extends StatefulWidget {
  const ProfileEditForm({
    super.key,
    required this.profile,
    required this.saving,
    required this.onCancel,
    required this.onSaved,
  });

  final ManagerProfile profile;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  Uint8List? _photo;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    _role = TextEditingController(text: widget.profile.role);
    _email = TextEditingController(text: widget.profile.email);
    _phone = TextEditingController(text: widget.profile.phone);
    _photo = widget.profile.photoBytes;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final bytes = await context.read<ProfileImagePicker>().pickImage();
      if (mounted && bytes != null && bytes.isNotEmpty) {
        setState(() => _photo = bytes);
      }
    } catch (_) {
      if (mounted) {
        ToastService.error(context, message: 'Could not open that image.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || widget.saving) return;
    final saved = await context.read<ProfileCubit>().update(
      widget.profile.copyWith(
        fullName: _name.text.trim(),
        role: _role.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        photoBytes: _photo,
      ),
    );
    if (!mounted) return;
    if (saved) {
      widget.onSaved();
      ToastService.success(context, message: 'Profile updated successfully');
    } else {
      ToastService.error(context, message: 'Could not update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.profile.copyWith(
      fullName: _name.text,
      photoBytes: _photo,
    );
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        key: const Key('profile-edit-content'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          const ScreenHeader(
            title: 'Edit Profile',
            subtitle: 'Update your manager information',
          ),
          const SizedBox(height: AppSpacing.l),
          Center(child: ProfileAvatar(profile: preview, radius: 44)),
          Center(
            child: TextButton.icon(
              key: const Key('change-photo'),
              onPressed: _picking || widget.saving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(_picking ? 'Opening gallery…' : 'Change photo'),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          ProfileEditField(
            key: const Key('profile-name-field'),
            controller: _name,
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            capitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().length ?? 0) < 3 ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 13),
          ProfileEditField(
            controller: _role,
            label: 'Role / title',
            icon: Icons.badge_outlined,
            capitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().length ?? 0) < 2 ? 'Enter your role' : null,
          ),
          const SizedBox(height: 13),
          ProfileEditField(
            key: const Key('profile-email-field'),
            controller: _email,
            label: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address',
          ),
          const SizedBox(height: 13),
          ProfileEditField(
            key: const Key('profile-phone-field'),
            controller: _phone,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                (value?.replaceAll(RegExp(r'\D'), '').length ?? 0) < 8
                ? 'Enter a valid phone number'
                : null,
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('cancel-profile-edit'),
                  onPressed: widget.saving ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('save-profile'),
                  onPressed: widget.saving ? null : _save,
                  child: widget.saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileEditField extends StatelessWidget {
  const ProfileEditField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    textInputAction: TextInputAction.next,
    validator: validator,
    onChanged: (_) => setStatePreview(context),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );

  void setStatePreview(BuildContext context) =>
      (context as Element).markNeedsBuild();
}
