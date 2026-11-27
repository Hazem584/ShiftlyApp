import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import 'employee_navigation_destinations.dart';

class EmployeeBottomNavigation extends StatelessWidget {
  const EmployeeBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatGroupsCubit, ChatGroupsState>(
        buildWhen: (before, after) => before.unreadCount != after.unreadCount,
        builder: (context, chat) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: NavigationBar(
            key: const Key('employee-bottom-navigation'),
            selectedIndex: selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: onSelected,
            destinations: buildEmployeeDestinations(context, chat.unreadCount),
          ),
        ),
      );
}
