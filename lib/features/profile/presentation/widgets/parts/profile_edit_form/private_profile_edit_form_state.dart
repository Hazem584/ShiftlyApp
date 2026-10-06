part of '../../profile_edit_form.dart';

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _picking = false;

  bool get _busy => widget.action != ProfileAction.idle || _picking;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName ?? '');
    _role = TextEditingController(text: widget.profile.role);
    _email = TextEditingController(text: widget.profile.email ?? '');
    _phone = TextEditingController(text: widget.profile.phone ?? '');
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
    if (_busy) return;
    setState(() => _picking = true);
    try {
      final image = await context.read<ProfileImagePicker>().pickImage();
      if (!mounted || image == null) return;
      final result = await context.read<ProfileCubit>().uploadAvatar(image);
      if (!mounted) return;
      _showAvatarResult(result);
    } catch (_) {
      if (mounted) {
        ToastService.error(context, message: 'Could not open that image.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showAvatarResult(ProfileOperationResult result) {
    switch (result) {
      case ProfileOperationResult.success:
        ToastService.success(context, message: 'Profile photo updated');
      case ProfileOperationResult.imageTooLarge:
        ToastService.error(context, message: 'Avatar must not exceed 2 MiB.');
      case ProfileOperationResult.unsupportedImage:
        ToastService.error(
          context,
          message: 'Choose a JPEG, PNG, or WebP image.',
        );
      case ProfileOperationResult.failure:
        ToastService.error(context, message: _failureMessage());
      case ProfileOperationResult.cancelled ||
          ProfileOperationResult.busy ||
          ProfileOperationResult.stale:
        break;
    }
  }

  String _failureMessage() {
    final state = context.read<ProfileCubit>().state;
    return state is ProfileLoaded
        ? state.failure?.message ?? 'Could not update profile.'
        : 'Could not update profile.';
  }

  Future<void> _deletePhoto() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text('Your initials will be shown instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-avatar'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await context.read<ProfileCubit>().deleteAvatar();
    if (!mounted) return;
    if (result == ProfileOperationResult.success) {
      ToastService.success(context, message: 'Profile photo removed');
    } else if (result == ProfileOperationResult.failure) {
      ToastService.error(context, message: _failureMessage());
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
      ToastService.error(context, message: _failureMessage());
    }
  }

  @override
  Widget build(BuildContext context) => Form(
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
        Center(child: ProfileAvatar(profile: widget.profile, radius: 44)),
        Center(
          child: TextButton.icon(
            key: const Key('change-photo'),
            onPressed: _busy ? null : _pickPhoto,
            icon: widget.action == ProfileAction.uploadingAvatar
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(
              _picking
                  ? 'Opening gallery…'
                  : widget.action == ProfileAction.uploadingAvatar
                  ? 'Uploading…'
                  : 'Change photo',
            ),
          ),
        ),
        if (widget.profile.avatarUrl != null ||
            widget.profile.photoBytes != null)
          Center(
            child: TextButton(
              key: const Key('delete-avatar'),
              onPressed: _busy ? null : _deletePhoto,
              child: Text(
                widget.action == ProfileAction.deletingAvatar
                    ? 'Removing…'
                    : 'Remove photo',
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s),
        ProfileEditField(
          key: const Key('profile-name-field'),
          controller: _name,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
          capitalization: TextCapitalization.words,
          enabled: !_busy,
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Enter your full name' : null,
        ),
        const SizedBox(height: 13),
        ProfileEditField(
          controller: _role,
          label: 'Role / title',
          icon: Icons.badge_outlined,
          enabled: !_busy,
          readOnly: true,
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
          enabled: !_busy,
          readOnly: true,
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
          enabled: !_busy,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) return null;
            return trimmed.replaceAll(RegExp(r'\D'), '').length < 8
                ? 'Enter a valid phone number'
                : null;
          },
        ),
        const SizedBox(height: AppSpacing.l),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('cancel-profile-edit'),
                onPressed: _busy ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const Key('save-profile'),
                onPressed: _busy ? null : _save,
                child: widget.action == ProfileAction.saving
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
