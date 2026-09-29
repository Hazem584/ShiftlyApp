import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';

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
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ink, AppColors.orange],
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workspaceName.isEmpty ? AppStrings.workplace : workspaceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              timezone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      const NotificationBell(),
      BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => state is ProfileLoaded
            ? ProfileAvatar(profile: state.profile, radius: 19)
            : const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                child: Text('M'),
              ),
      ),
    ],
  );
}
