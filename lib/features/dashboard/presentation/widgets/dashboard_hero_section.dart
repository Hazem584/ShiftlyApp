import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';

import 'dashboard_hero_chip.dart';

class DashboardHeroSection extends StatelessWidget {
  const DashboardHeroSection({required this.data, super.key});
  final ManagerDashboardData data;
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [colors.brandBackground, colors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3ED6C3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr('Your workday, in sync'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3ED6C3),
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('Good morning, Manager!'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    context.tr("Here's what's happening with your team today."),
                    style: const TextStyle(
                      color: Color(0xFFB0C4CB),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DashboardHeroChip(
                      icon: Icons.groups_outlined,
                      label: context.tr('{value1} employees', {
                        'value1': data.summary.totalEmployees.toString(),
                      }),
                    ),
                    DashboardHeroChip(
                      icon: Icons.check_circle_outline,
                      label: context.tr('{value1} clocked in', {
                        'value1': data.summary.clockedInNow.toString(),
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
          ),
        ],
      ),
    );
  }
}
