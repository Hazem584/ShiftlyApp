import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_colors.dart';

part 'parts/profile_avatar/private_profile_avatar_state.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 22});

  final ManagerProfile profile;
  final double radius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}
