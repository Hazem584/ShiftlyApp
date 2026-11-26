import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/widgets/access_screen.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<SessionCoordinator, SessionState>(
        listenWhen: (previous, current) =>
            current.status == SessionStatus.emailVerificationRequired &&
            current.failure != null &&
            previous.failure != current.failure,
        listener: (context, state) =>
            ToastService.error(context, message: state.failure!.message),
        builder: (context, state) {
          final email = state.verificationEmail ?? '';
          return AccessScreen(
            title: 'Verify your email',
            actions: [
              FilledButton(
                onPressed: state.resendingVerification
                    ? null
                    : context.read<SessionCoordinator>().retry,
                child: Text(context.tr('I’ve verified my email')),
              ),
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
              TextButton(
                key: const Key('verification-back-to-login'),
                onPressed: state.resendingVerification
                    ? null
                    : context.read<SessionCoordinator>().signOut,
                child: Text(context.tr('Back to sign in')),
              ),
            ],
            children: [
              Text(context.tr('One more step to protect your account.')),
              const SizedBox(height: 24),
              Text(
                context.tr('Check your inbox.'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mark_email_read_outlined),
                  title: Text(context.tr('Verification sent')),
                  subtitle: SelectableText(
                    email,
                    key: const Key('verification-email'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  'Open the verification link in your email, then return here to continue.',
                ),
              ),
            ],
          );
        },
      );
}
