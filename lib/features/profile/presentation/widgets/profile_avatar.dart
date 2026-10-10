import 'package:flutter/material.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/theme/app_palette.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 22});

  final ManagerProfile profile;
  final double radius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _networkFailed = false;

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.avatarUrl != widget.profile.avatarUrl) {
      _networkFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = widget.profile.photoBytes;
    final avatarUrl = widget.profile.avatarUrl;
    final ImageProvider<Object>? image = bytes != null && bytes.isNotEmpty
        ? MemoryImage(bytes)
        : avatarUrl != null && avatarUrl.isNotEmpty && !_networkFailed
        ? NetworkImage(avatarUrl)
        : null;
    return CircleAvatar(
      key: const Key('profile-avatar'),
      radius: widget.radius,
      backgroundColor: AppPalette.of(context).brandBackground,
      foregroundColor: Colors.white,
      backgroundImage: image,
      onBackgroundImageError: image == null
          ? null
          : (_, _) {
              if (avatarUrl != null && mounted) {
                setState(() => _networkFailed = true);
              }
            },
      child: image == null
          ? Text(
              widget.profile.initials,
              key: const Key('profile-initials'),
              style: TextStyle(
                fontSize: widget.radius * .55,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
