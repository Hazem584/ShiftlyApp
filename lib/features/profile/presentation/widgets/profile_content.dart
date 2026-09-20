import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileError(:final message) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            message: message,
            action: FilledButton(
              onPressed: context.read<ProfileCubit>().load,
              child: const Text('Retry'),
            ),
          ),
          ProfileLoaded(:final profile, :final saving) =>
            _editing
                ? _ProfileEditor(
                    key: const Key('profile-editor'),
                    profile: profile,
                    saving: saving,
                    onCancel: () => setState(() => _editing = false),
                    onSaved: () => setState(() => _editing = false),
                  )
                : _ProfileView(
                    profile: profile,
                    onEdit: () => setState(() => _editing = true),
                  ),
        },
      ),
    ),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onEdit});
  final ManagerProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('profile-content'),
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
    children: [
      ScreenHeader(
        title: 'Manager Profile',
        subtitle: 'Your personal and workplace information',
        action: FilledButton.icon(
          key: const Key('edit-profile'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: const Text('Edit'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(82, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.l),
      SurfaceCard(
        child: Column(
          children: [
            ProfileAvatar(profile: profile, radius: 48),
            const SizedBox(height: 13),
            Text(
              profile.fullName,
              key: const Key('profile-name'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 3),
            Text(
              profile.role,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  profile.workplace,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      Text(
        'Contact information',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email address',
              value: profile.email,
            ),
            const Divider(height: 1, indent: 58),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone number',
              value: profile.phone,
            ),
            const Divider(height: 1, indent: 58),
            _InfoRow(
              icon: Icons.business_outlined,
              label: 'Workplace',
              value: profile.workplace,
            ),
          ],
        ),
      ),
    ],
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.profile, this.radius = 22, super.key});
  final ManagerProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = profile.photoBytes;
    return CircleAvatar(
      key: const Key('profile-avatar'),
      radius: radius,
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      backgroundImage: bytes == null || bytes.isEmpty
          ? null
          : MemoryImage(bytes),
      onBackgroundImageError: bytes == null || bytes.isEmpty ? null : (_, _) {},
      child: bytes == null || bytes.isEmpty
          ? Text(
              profile.initials,
              key: const Key('profile-initials'),
              style: TextStyle(
                fontSize: radius * .55,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({
    required this.profile,
    required this.saving,
    required this.onCancel,
    required this.onSaved,
    super.key,
  });
  final ManagerProfile profile;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
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
          _EditField(
            key: const Key('profile-name-field'),
            controller: _name,
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            capitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().length ?? 0) < 3 ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 13),
          _EditField(
            controller: _role,
            label: 'Role / title',
            icon: Icons.badge_outlined,
            capitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().length ?? 0) < 2 ? 'Enter your role' : null,
          ),
          const SizedBox(height: 13),
          _EditField(
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
          _EditField(
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

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    super.key,
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
    onChanged: (_) => (context as Element).markNeedsBuild(),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}
