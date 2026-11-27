import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/auth_brand_header.dart';

List<Widget> buildProfileSetupFields(
  BuildContext context, {
  required bool loading,
  required TextEditingController nameController,
  required TextEditingController phoneController,
  required VoidCallback onSubmit,
}) => [
  AuthBrandHeader(
    title: context.tr('How should your team know you?'),
    subtitle: context.tr(
      'Tell us how your name and phone should appear in Shiftly.',
    ),
  ),
  const SizedBox(height: AppSpacing.l),
  TextFormField(
    key: const Key('profile-setup-name'),
    controller: nameController,
    enabled: !loading,
    decoration: InputDecoration(labelText: context.tr('Full name')),
    validator: (value) {
      final length = value?.trim().length ?? 0;
      if (length < 1) return context.tr('Full name is required');
      if (length > 120) return context.tr('Full name is too long');
      return null;
    },
  ),
  const SizedBox(height: AppSpacing.m),
  TextFormField(
    key: const Key('profile-setup-phone'),
    controller: phoneController,
    enabled: !loading,
    keyboardType: TextInputType.phone,
    decoration: InputDecoration(labelText: context.tr('Phone (optional)')),
    validator: (value) => (value?.trim().length ?? 0) > 30
        ? context.tr('Phone number is too long')
        : null,
  ),
  const SizedBox(height: AppSpacing.l),
  FilledButton(
    key: const Key('profile-setup-submit'),
    onPressed: loading ? null : onSubmit,
    child: loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : Text(context.tr('Continue')),
  ),
];
