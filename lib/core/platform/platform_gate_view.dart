import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';

import 'platform_blocked_screen.dart';
import 'platform_gate_content.dart';

class PlatformGateView extends StatelessWidget {
  const PlatformGateView({
    required this.child,
    required this.status,
    required this.suspension,
    required this.failed,
    required this.checking,
    required this.onRefresh,
    required this.onSignOut,
    super.key,
  });

  final Widget child;
  final Map<String, dynamic>? status;
  final String? suspension;
  final bool failed, checking;
  final Future<void> Function() onRefresh, onSignOut;

  @override
  Widget build(BuildContext context) {
    if (status == null && !failed && suspension == null) {
      return const BrandSessionLoading();
    }
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final blocked =
        status == null ||
        status?['mode'] != 'OPERATIONAL' ||
        suspension != null;
    final announcement = status?['announcement']?.toString().trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: TickerMode(
            enabled: !blocked,
            child: ExcludeFocus(
              excluding: blocked,
              child: Column(
                children: [
                  if (announcement.isNotEmpty)
                    buildPlatformAnnouncementBanner(context, announcement),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
        if (blocked)
          PlatformBlockedScreen(
            arabic: arabic,
            status: status,
            suspension: suspension,
            failed: failed,
            checking: checking,
            onRefresh: onRefresh,
            onSignOut: onSignOut,
          ),
      ],
    );
  }
}
