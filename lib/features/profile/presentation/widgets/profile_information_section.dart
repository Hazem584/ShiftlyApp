import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_info_row.dart';

class ProfileInformationSection extends StatelessWidget {
  const ProfileInformationSection({super.key, required this.profile});

  final ManagerProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Contact information'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ProfileInfoRow(
              icon: Icons.email_outlined,
              label: context.tr('Email address'),
              value: profile.displayEmail,
            ),
            const Divider(height: 1, indent: 58),
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: context.tr('Phone number'),
              value: profile.displayPhone,
            ),
            const Divider(height: 1, indent: 58),
            ProfileInfoRow(
              icon: Icons.business_outlined,
              label: context.tr('Workplace'),
              value: profile.workplace,
            ),
          ],
        ),
      ),
    ],
  );
}
