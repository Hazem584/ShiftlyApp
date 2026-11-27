import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shiftly/core/utils/workspace_time.dart';

import 'message_delivery_status.dart';

class ChatMessageDeliveryFooter extends StatelessWidget {
  const ChatMessageDeliveryFooter({
    required this.createdAt,
    required this.timezone,
    required this.mine,
    required this.readByAll,
    required this.foreground,
    super.key,
  });
  final DateTime createdAt;
  final String timezone;
  final bool mine, readByAll;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.Hm(Localizations.localeOf(context).toString())
              .format(WorkspaceTime.inWorkspace(createdAt, timezone)),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground.withValues(alpha: .72)),
        ),
        if (mine) ...[
          const SizedBox(width: 5),
          MessageDeliveryStatus(readByAll: readByAll),
        ],
      ],
    ),
  );
}
