import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

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
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: context.tr('Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: context.tr('My Shifts'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_outlined),
                selectedIcon: const Icon(Icons.check),
                label: context.tr('Tasks'),
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: chat.unreadCount > 0,
                  label: Text(
                    chat.unreadCount > 99
                        ? '99+'
                        : context.tr('{value1}', {
                            'value1': (chat.unreadCount).toString(),
                          }),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: chat.unreadCount > 0,
                  label: Text(
                    chat.unreadCount > 99
                        ? '99+'
                        : context.tr('{value1}', {
                            'value1': (chat.unreadCount).toString(),
                          }),
                  ),
                  child: const Icon(Icons.chat_bubble_rounded),
                ),
                label: context.tr('Chat'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: context.tr('Profile'),
              ),
            ],
          ),
        ),
      );
}
