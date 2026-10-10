import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class MessageDeliveryStatus extends StatelessWidget {
  const MessageDeliveryStatus({
    super.key,
    this.pending = false,
    this.failed = false,
    this.readByAll = false,
  });

  final bool pending, failed, readByAll;

  @override
  Widget build(BuildContext context) {
    final label = context.tr(
      failed
          ? 'Message failed to send.'
          : pending
          ? 'Sending'
          : readByAll
          ? 'Read by everyone'
          : 'Sent',
    );
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          child: Icon(
            key: ValueKey((pending, failed, readByAll)),
            failed
                ? Icons.error_outline_rounded
                : pending
                ? Icons.schedule_rounded
                : readByAll
                ? Icons.done_all_rounded
                : Icons.check_rounded,
            size: 16,
            color: failed
                ? Theme.of(context).colorScheme.error
                : readByAll
                ? const Color(0xFF007B83)
                : null,
          ),
        ),
      ),
    );
  }
}
