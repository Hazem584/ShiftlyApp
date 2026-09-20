import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class ProfileInformationSection extends StatelessWidget {
  const ProfileInformationSection({super.key, required this.profile});

  final ManagerProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Contact information',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email address',
              value: profile.email,
            ),
            const Divider(height: 1, indent: 58),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone number',
              value: profile.phone,
            ),
            const Divider(height: 1, indent: 58),
            _InfoRow(
              icon: Icons.business_outlined,
              label: 'Workplace',
              value: profile.workplace,
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
