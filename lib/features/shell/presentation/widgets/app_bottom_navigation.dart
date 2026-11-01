import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';

import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/shell/presentation/widgets/navigation_destination_item.dart';

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
        builder: (context, chat) => Padding(
          padding: EdgeInsets.zero,
          child: DecoratedBox(
            key: const Key('manager-bottom-navigation'),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              border: Border.all(color: AppPalette.of(context).borderColor),
              borderRadius: BorderRadius.zero,
              boxShadow: const [],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 40 + MediaQuery.textScalerOf(context).scale(12) * 3.2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(12) / 12;
                    final width = scale > 1.3
                        ? (MediaQuery.textScalerOf(context).scale(72) *
                                  _destinations.length)
                              .clamp(constraints.maxWidth, double.infinity)
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        child: Row(
                          children: [
                            for (
                              var index = 0;
                              index < _destinations.length;
                              index++
                            )
                              NavigationDestinationItem(
                                icon: selectedIndex == index
                                    ? _destinations[index].$2
                                    : _destinations[index].$1,
                                label: context.tr(_destinations[index].$3),
                                index: index,
                                selected: selectedIndex == index,
                                onTap: () => onDestinationSelected(index),
                                badgeCount: index == 3 ? chat.unreadCount : 0,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
}
