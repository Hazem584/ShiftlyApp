import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final ManagerProfile profile;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      children: [
        ProfileAvatar(profile: profile, radius: 48),
        const SizedBox(height: 13),
        Text(
          profile.displayName,
          key: const Key('profile-name'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 3),
        Text(
          profile.role,
          style: TextStyle(color: AppPalette.of(context).textSecondary),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppPalette.of(context).tealSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              profile.workplace,
              style: TextStyle(
                color: AppPalette.of(context).teal,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
