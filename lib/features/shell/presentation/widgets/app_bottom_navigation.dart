import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Team'),
    (Icons.work_outline_rounded, Icons.work_rounded, 'Work'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
    (Icons.person_outline_rounded, Icons.person_rounded, AppStrings.profile),
  ];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => NavigationBar(
          key: const Key('manager-bottom-navigation'),
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (var index = 0; index < _destinations.length; index++)
              NavigationDestination(
                key: Key('nav-$index'),
                icon: Badge(
                  isLabelVisible: index == 3 && chat.unreadCount > 0,
                  label: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                  ),
                  child: Icon(_destinations[index].$1),
                ),
                selectedIcon: Icon(_destinations[index].$2),
                label: context.tr(_destinations[index].$3),
              ),
          ],
        ),
      );
}
