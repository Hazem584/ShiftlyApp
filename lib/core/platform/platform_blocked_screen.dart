import 'package:flutter/material.dart';
import 'package:shiftly/core/platform/platform_gate_content.dart';

class PlatformBlockedScreen extends StatelessWidget {
  const PlatformBlockedScreen({
    super.key,
    required this.arabic,
    required this.status,
    required this.suspension,
    required this.failed,
    required this.checking,
    required this.onRefresh,
    required this.onSignOut,
  });

  final bool arabic;
  final Map<String, dynamic>? status;
  final String? suspension;
  final bool failed;
  final bool checking;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final title = resolvePlatformBlockedTitle(
      arabic: arabic,
      status: status,
      suspension: suspension,
    );
    final message = resolvePlatformBlockedMessage(
      arabic: arabic,
      status: status,
      suspension: suspension,
    );
    final supportEmail = status?['supportEmail']?.toString() ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    suspension != null
                        ? Icons.person_off_outlined
                        : Icons.construction_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (status != null || suspension != null)
                    Text(message, textAlign: TextAlign.center),
                  if (failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        arabic
                            ? 'تعذّر الاتصال بالخدمة. تحقّق من الإنترنت وأعد المحاولة.'
                            : 'Could not reach the service. Check your connection and retry.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (supportEmail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SelectableText(supportEmail),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: checking ? null : onRefresh,
                    icon: checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(arabic ? 'إعادة المحاولة' : 'Try again'),
                  ),
                  if (suspension != null)
                    TextButton(
                      onPressed: onSignOut,
                      child: Text(arabic ? 'تسجيل الخروج' : 'Sign out'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
