import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_hero_chip.dart';

class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({required this.data, super.key});
  final ManagerDashboardData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.ink, AppColors.inkMuted, AppColors.orange],
        stops: [0, .62, 1],
      ),
      borderRadius: BorderRadius.circular(AppRadii.xl),
      boxShadow: AppShadows.soft,
    ),
    child: Stack(
      children: [
        Positioned(
          right: -28,
          top: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 28,
          bottom: -36,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Good morning, Manager!'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr("Here's what's happening with your team today."),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .88),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DashboardHeroChip(
                  icon: Icons.groups_outlined,
                  label: context.tr('{value1} employees', {
                    'value1': (data.summary.totalEmployees).toString(),
                  }),
                ),
                DashboardHeroChip(
                  icon: Icons.check_circle_outline,
                  label: context.tr('{value1} clocked in', {
                    'value1': (data.summary.clockedInNow).toString(),
                  }),
                ),
                DashboardHeroChip(
                  icon: Icons.calendar_today_outlined,
                  label: data.date,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
