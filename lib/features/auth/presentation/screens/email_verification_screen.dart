import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SessionCoordinator, SessionState>(
    listenWhen: (previous, current) =>
        current.status == SessionStatus.emailVerificationRequired &&
        current.failure != null &&
        previous.failure != current.failure,
    listener: (context, state) =>
        ToastService.error(context, message: state.failure!.message),
    builder: (context, state) {
      final email = state.verificationEmail ?? '';
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 52),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      context.tr('Verify your email'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      context.tr('We sent a confirmation email to:'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    SelectableText(
                      email,
                      key: const Key('verification-email'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      context.tr(
                        'Open the link in your browser. If the app does not reopen automatically, return here and sign in after verification.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    OutlinedButton.icon(
                      key: const Key('resend-verification'),
                      onPressed: state.resendingVerification || email.isEmpty
                          ? null
                          : () async {
                              final success = await context
                                  .read<SessionCoordinator>()
                                  .resendVerificationEmail();
                              if (success && context.mounted) {
                                ToastService.success(
                                  context,
                                  message: 'Confirmation email resent.',
                                );
                              }
                            },
                      icon: state.resendingVerification
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(context.tr('Resend confirmation email')),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextButton(
                      key: const Key('verification-back-to-login'),
                      onPressed: state.resendingVerification
                          ? null
                          : context.read<SessionCoordinator>().signOut,
                      child: Text(context.tr('Back to sign in')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
