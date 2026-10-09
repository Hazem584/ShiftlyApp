import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_avatar.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    required this.workspaceName,
    required this.timezone,
    super.key,
  });

  final String workspaceName;
  final String timezone;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.s),
        child: const BrandLogo(size: 42),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workspaceName.isEmpty ? AppStrings.workplace : workspaceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              timezone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      const NotificationBell(),
      const SizedBox(width: 6),
      BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => state is ProfileLoaded
            ? ProfileAvatar(profile: state.profile, radius: 20)
            : const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                child: Text('M'),
              ),
      ),
    ],
  );
}
