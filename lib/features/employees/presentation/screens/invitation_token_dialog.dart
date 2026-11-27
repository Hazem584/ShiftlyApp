import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<void> submitEmployeeInvitation(
  BuildContext context, {
  required String email,
  required String? jobTitle,
  required VoidCallback? onDone,
}) async {
  try {
    final invitation = await context.read<EmployeesCubit>().invite(
      email: email,
      jobTitle: jobTitle,
    );
    if (!context.mounted || invitation == null) return;
    final token = invitation.inviteToken;
    if (token != null) await showInvitationTokenDialog(context, token);
    if (context.mounted) {
      if (onDone != null) {
        ToastService.success(
          context,
          message: 'Invitation created successfully',
        );
        onDone();
      } else {
        context.pop(true);
      }
    }
  } on ApiException catch (error) {
    if (context.mounted) {
      ToastService.error(context, message: error.toFailure().message);
    }
  } catch (_) {
    if (context.mounted) {
      ToastService.error(context, message: 'Could not create invitation.');
    }
  }
}

Future<void> showInvitationTokenDialog(BuildContext context, String token) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ManagerDialog(
        title: Text(context.tr('Invitation created')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'Share this one-time token only with the intended employee.',
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(token, key: const Key('invitation-token')),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('copy-invitation-token'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (dialogContext.mounted) {
                ToastService.success(dialogContext, message: 'Token copied');
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(context.tr('Copy')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('Done')),
          ),
        ],
      ),
    );
