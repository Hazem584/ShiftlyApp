part of '../../shift_card.dart';

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    required this.shift,
    required this.timezone,
    this.onTap,
    this.trailing,
    super.key,
  });

  final ShiftRecord shift;
  final String timezone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.schedule_rounded,
              size: 22,
              color: AppColors.orange,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.employee.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                WorkspaceTime.dateTime(
                  shift.startsAt,
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'to ${WorkspaceTime.dateTime(shift.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              ShiftStatusBadge(status: shift.status),
            ],
          ),
        ),
        if (trailing != null) trailing! else const Icon(Icons.chevron_right),
      ],
    ),
  );
}
