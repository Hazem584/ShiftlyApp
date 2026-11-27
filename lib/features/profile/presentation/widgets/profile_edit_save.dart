import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

import 'profile_photo_dialogs.dart';

Future<void> saveProfileEdit(
  BuildContext context,
  String name,
  String phoneInput,
  VoidCallback onSaved,
) async {
  final phone = phoneInput.trim();
  final result = await context.read<ProfileCubit>().update(
    fullName: name.trim(),
    phone: phone.isEmpty ? null : phone,
  );
  if (!context.mounted) return;
  if (result == ProfileOperationResult.success) {
    onSaved();
    ToastService.success(context, message: 'Profile updated successfully');
  } else if (result == ProfileOperationResult.failure) {
    ToastService.error(context, message: profileFailureMessage(context));
  }
}
