import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

/// Home previews never create read or acknowledgment receipts.
class ManagerAnnouncementPreview extends StatelessWidget {
  const ManagerAnnouncementPreview({required this.announcement, super.key});
  final TeamAnnouncement announcement;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppPalette.of(context).selected,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          announcement.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          announcement.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (announcement.requiresAcknowledgment) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('Acknowledgment required'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        TextButton(
          onPressed: () => context.go('/work?tab=announcements'),
          child: Text(context.tr('View announcement')),
        ),
      ],
    ),
  );
}
