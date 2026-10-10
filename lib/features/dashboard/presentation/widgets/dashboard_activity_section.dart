import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_shift_tile.dart';

class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({
    required this.shifts,
    required this.timezone,
    super.key,
  });

  final List<DashboardShiftPreview> shifts;
  final String timezone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr("Today's shifts"),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: shifts.isEmpty ? const EdgeInsets.all(20) : EdgeInsets.zero,
        child: shifts.isEmpty
            ? Column(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.orange,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'No shifts are scheduled for this workspace day.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.managerShifts),
                    child: Text(context.tr('Create a shift')),
                  ),
                ],
              )
            : Column(
                children: [
                  for (var index = 0; index < shifts.length; index++) ...[
                    DashboardShiftTile(
                      shift: shifts[index],
                      timezone: timezone,
                    ),
                    if (index < shifts.length - 1)
                      const Divider(height: 1, indent: 64, endIndent: 14),
                  ],
                ],
              ),
      ),
    ],
  );
}
