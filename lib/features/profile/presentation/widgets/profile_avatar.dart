import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 22});

  final ManagerProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = profile.photoBytes;
    return CircleAvatar(
      key: const Key('profile-avatar'),
      radius: radius,
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      backgroundImage: bytes == null || bytes.isEmpty
          ? null
          : MemoryImage(bytes),
      onBackgroundImageError: bytes == null || bytes.isEmpty ? null : (_, _) {},
      child: bytes == null || bytes.isEmpty
          ? Text(
              profile.initials,
              key: const Key('profile-initials'),
              style: TextStyle(
                fontSize: radius * .55,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
