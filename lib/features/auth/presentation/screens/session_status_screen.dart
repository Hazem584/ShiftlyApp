import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../widgets/access_session_loading.dart';

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
    if (view == SessionStatusView.loading) return const AccessSessionLoading();
    final state = context.watch<SessionCoordinator>().state;
    final offline = view == SessionStatusView.offline;
    final verify = view == SessionStatusView.verification;
    return AccessPage(
      title: offline
          ? 'Offline startup'
          : verify
          ? 'Verify email'
          : 'Service unavailable',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!verify)
            AccessAction(
              label: context.tr('Retry'),
              onPressed: context.read<SessionCoordinator>().retry,
            ),
          TextButton(
            onPressed: context.read<SessionCoordinator>().signOut,
            child: Text(context.tr(verify ? 'Back to sign in' : 'Sign out')),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              offline
                  ? 'You’re offline.'
                  : verify
                  ? 'Check your inbox.'
                  : 'We’ll be back shortly.',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 48),
          AccessNotice(
            offline
                ? 'We can’t verify your saved session yet. Connect to the internet and try again.'
                : verify
                ? 'Open the verification email, then return and sign in.'
                : 'Shiftly couldn’t reach the service. Your saved information is still here. Try again in a moment.',
          ),
          if (state.failure != null) ...[
            const SizedBox(height: 16),
            AccessNotice('', failure: state.failure),
          ],
        ],
      ),
    );
  }
}
