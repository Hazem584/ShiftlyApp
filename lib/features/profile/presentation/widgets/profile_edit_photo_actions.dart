import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

import 'profile_photo_dialogs.dart';

Future<void> pickProfileEditPhoto(BuildContext context) async {
  try {
    final image = await context.read<ProfileImagePicker>().pickImage();
    if (!context.mounted || image == null) return;
    final result = await context.read<ProfileCubit>().uploadAvatar(image);
    if (context.mounted) showProfileAvatarResult(context, result);
  } catch (_) {
    if (context.mounted) {
      ToastService.error(context, message: 'Could not open that image.');
    }
  }
}

Future<void> deleteProfileEditPhoto(BuildContext context) async {
  if (!await confirmDeleteProfilePhoto(context) || !context.mounted) return;
  final result = await context.read<ProfileCubit>().deleteAvatar();
  if (!context.mounted) return;
  if (result == ProfileOperationResult.success) {
    ToastService.success(context, message: 'Profile photo removed');
  } else if (result == ProfileOperationResult.failure) {
    ToastService.error(context, message: profileFailureMessage(context));
  }
}
