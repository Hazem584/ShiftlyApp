import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({required this.data, super.key});
  final DashboardData data;

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
                  label: '${data.totalEmployees} employees',
                ),
                _HeroChip(
                  icon: Icons.check_circle_outline,
                  label: '${data.presentEmployees} active today',
                ),
                _HeroChip(
                  icon: Icons.calendar_today_outlined,
                  label: _date(DateTime.now()),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

String _date(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
