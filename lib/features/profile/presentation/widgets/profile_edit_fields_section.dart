import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_field.dart';

List<Widget> buildProfileEditFormContent(
  BuildContext context, {
  required ManagerProfile profile,
  required bool busy,
  required bool picking,
  required VoidCallback onPhotoOptions,
  required TextEditingController nameController,
  required TextEditingController emailController,
  required TextEditingController phoneController,
}) => [
  Center(child: ProfileAvatar(profile: profile, radius: 44)),
  Center(
    child: TextButton.icon(
      key: const Key('change-photo'),
      onPressed: busy ? null : onPhotoOptions,
      icon: const Icon(Icons.photo_camera_outlined),
      label: Text(context.tr(picking ? 'Opening gallery…' : 'Change photo')),
    ),
  ),
  const SizedBox(height: 24),
  ProfileEditField(
    key: const Key('profile-name-field'),
    controller: nameController,
    label: context.tr('Full name'),
    icon: Icons.person_outline_rounded,
    capitalization: TextCapitalization.words,
    enabled: !busy,
    validator: (v) =>
        (v?.trim().isEmpty ?? true) ? 'Enter your full name' : null,
  ),
  const SizedBox(height: 13),
  ProfileEditField(
    key: const Key('profile-email-field'),
    controller: emailController,
    label: context.tr('Account email'),
    icon: Icons.email_outlined,
    keyboardType: TextInputType.emailAddress,
    enabled: !busy,
    readOnly: true,
    validator: (v) =>
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
        ? null
        : 'Enter a valid email address',
  ),
  const SizedBox(height: 13),
  ProfileEditField(
    key: const Key('profile-phone-field'),
    controller: phoneController,
    label: context.tr('Phone number'),
    icon: Icons.phone_outlined,
    keyboardType: TextInputType.phone,
    enabled: !busy,
    validator: (v) {
      final trimmed = v?.trim() ?? '';
      if (trimmed.isEmpty) return null;
      return trimmed.replaceAll(RegExp(r'\D'), '').length < 8
          ? 'Enter a valid phone number'
          : null;
    },
  ),
];
