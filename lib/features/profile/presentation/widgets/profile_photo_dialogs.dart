import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

void showProfileAvatarResult(
  BuildContext context,
  ProfileOperationResult result,
) {
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
      ToastService.error(context, message: profileFailureMessage(context));
    case ProfileOperationResult.cancelled ||
        ProfileOperationResult.busy ||
        ProfileOperationResult.stale:
      break;
  }
}

String profileFailureMessage(BuildContext context) {
  final state = context.read<ProfileCubit>().state;
  return state is ProfileLoaded
      ? state.failure?.message ?? 'Could not update profile.'
      : 'Could not update profile.';
}

Future<bool> confirmDeleteProfilePhoto(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('Remove profile photo?')),
      content: Text(context.tr('Your initials will be shown instead.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-delete-avatar'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr('Remove')),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<String?> showProfilePhotoOptionsSheet(
  BuildContext context,
  ManagerProfile profile,
) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (c) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(c.tr('Profile photo')),
            subtitle: Text(c.tr('Choose how to update your photo.')),
          ),
          ListTile(
            key: const Key('replace-profile-photo'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(c.tr('Replace photo')),
            subtitle: Text(c.tr('Choose from your library')),
            onTap: () => Navigator.pop(c, 'replace'),
          ),
          if (profile.avatarUrl != null || profile.photoBytes != null)
            ListTile(
              key: const Key('delete-avatar'),
              leading: const Icon(Icons.delete_outline),
              title: Text(c.tr('Remove photo')),
              subtitle: Text(c.tr('Use your initials instead')),
              onTap: () => Navigator.pop(c, 'remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(c.tr('Cancel')),
          ),
        ],
      ),
    ),
  ),
);
