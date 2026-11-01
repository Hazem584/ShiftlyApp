import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';
import '../design/access_tile.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _resent = false;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    final success = await context
        .read<SessionCoordinator>()
        .resendVerificationEmail();
    if (!mounted || !success) return;
    setState(() {
      _seconds = 60;
      _resent = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, state) {
          final email = state.verificationEmail ?? '';
          final busy = state.resendingVerification;
          return AccessPage(
            title: 'Verify email',
            subtitle: 'One more step to protect your account.',
            onBack: busy ? null : context.read<SessionCoordinator>().signOut,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Verification is completed through the existing email/auth flow. With
                // no authenticated session the user must sign in, never fake success.
                AccessAction(
                  actionKey: const Key('verification-back-to-login'),
                  label: context.tr('I’ve verified my email'),
                  onPressed: busy
                      ? null
                      : context.read<SessionCoordinator>().signOut,
                ),
                TextButton(
                  key: const Key('resend-verification'),
                  onPressed: busy || email.isEmpty || _seconds > 0
                      ? null
                      : _resend,
                  child: Text(
                    busy
                        ? context.tr('Sending…')
                        : _seconds > 0
                        ? context.tr('Resend email · available in {time}', {
                            'time': '00:${_seconds.toString().padLeft(2, '0')}',
                          })
                        : context.tr('Resend confirmation email'),
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('Check your inbox.'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 48),
                AccessTile(
                  key: const Key('verification-email'),
                  title: context.tr('Verification sent'),
                  subtitle: email,
                  icon: 'file',
                ),
                const SizedBox(height: 12),
                const AccessNotice(
                  'Open the verification link in your email, then return here to continue.',
                ),
                if (_resent) ...[
                  const SizedBox(height: 16),
                  const AccessNotice('Confirmation email resent.'),
                ],
                if (state.failure != null) ...[
                  const SizedBox(height: 16),
                  AccessNotice('', failure: state.failure),
                ],
              ],
            ),
          );
        },
      );
}
