import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

InputDecoration buildRegisterPasswordDecoration(
  BuildContext context, {
  required String label,
  required String tooltip,
  required bool obscure,
  required bool loading,
  required VoidCallback onToggle,
}) => InputDecoration(
  labelText: context.tr(label),
  prefixIcon: const Icon(Icons.lock_outline_rounded),
  suffixIcon: IconButton(
    tooltip: context.tr(tooltip),
    onPressed: loading ? null : onToggle,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
  ),
);

String? validateRegisterEmail(BuildContext context, String? value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value?.trim() ?? '')
    ? null
    : context.tr('Enter a valid email address');

String? validateRegisterPassword(BuildContext context, String? value) =>
    (value ?? '').trim().isEmpty
    ? context.tr('Password is required')
    : (value!.length < 8 ? context.tr('Use at least 8 characters') : null);
