import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';

enum SessionStatusView { loading, offline, failure, verification }

class SessionStatusScreen extends StatelessWidget {
  const SessionStatusScreen.loading({super.key})
    : view = SessionStatusView.loading;
  const SessionStatusScreen.offline({super.key})
    : view = SessionStatusView.offline;
  const SessionStatusScreen.failure({super.key})
    : view = SessionStatusView.failure;
  const SessionStatusScreen.emailVerification({super.key})
    : view = SessionStatusView.verification;

  final SessionStatusView view;

  @override
  Widget build(BuildContext context) {
    if (view == SessionStatusView.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final state = context.watch<SessionCoordinator>().state;
    final (icon, title, message) = switch (view) {
      SessionStatusView.offline => (
        Icons.cloud_off_outlined,
        'You are offline',
        state.failure?.message ?? 'Connect to the internet and retry.',
      ),
      SessionStatusView.verification => (
        Icons.mark_email_read_outlined,
        'Verify your email',
        'Open the verification email, then return and sign in.',
      ),
      _ => (
        Icons.error_outline_rounded,
        'Could not load your account',
        state.failure?.message ?? 'Please try again.',
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 52),
                const SizedBox(height: AppSpacing.m),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.s),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.l),
                if (view != SessionStatusView.verification)
                  FilledButton.icon(
                    onPressed: context.read<SessionCoordinator>().retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                TextButton(
                  onPressed: context.read<SessionCoordinator>().signOut,
                  child: Text(
                    view == SessionStatusView.verification
                        ? 'Back to sign in'
                        : 'Sign out',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
