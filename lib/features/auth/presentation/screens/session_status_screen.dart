import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';

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
      return const BrandSessionLoading();
    }
    final state = context.watch<SessionCoordinator>().state;
    final (title, heading, icon) = switch (view) {
      SessionStatusView.offline => (
        'Offline startup',
        'You are offline',
        Icons.cloud_off_outlined,
      ),
      SessionStatusView.verification => (
        'Verify your email',
        'Check your inbox.',
        Icons.mark_email_read_outlined,
      ),
      _ => ('Service unavailable', 'We’ll be back shortly.', Icons.cloud_queue),
    };
    final session = context.read<SessionCoordinator>();
    return AccessScreen(
      title: title,
      actions: [
        if (view != SessionStatusView.verification)
          FilledButton(
            onPressed: session.retry,
            child: Text(context.tr('Try again')),
          ),
        TextButton(
          onPressed: session.signOut,
          child: Text(
            context.tr(
              view == SessionStatusView.verification
                  ? 'Back to sign in'
                  : 'Sign out',
            ),
          ),
        ),
      ],
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Icon(
            icon,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr(heading),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          context.tr(
            state.failure?.message ?? 'Connect to the internet and retry.',
          ),
        ),
      ],
    );
  }
}
