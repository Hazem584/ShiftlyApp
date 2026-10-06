import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

part 'parts/dashboard_hero_section/private_hero_chip.dart';

class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({required this.data, super.key});
  final ManagerDashboardData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.ink, AppColors.orange, AppColors.teal],
        stops: [0, .55, 1],
      ),
      borderRadius: BorderRadius.circular(AppRadii.xl),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -32,
          top: -45,
          child: Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, Manager! 👋',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your team today.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(
                  icon: Icons.groups_outlined,
                  label: '${data.summary.totalEmployees} employees',
                ),
                _HeroChip(
                  icon: Icons.check_circle_outline,
                  label: '${data.summary.clockedInNow} clocked in',
                ),
                _HeroChip(
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
