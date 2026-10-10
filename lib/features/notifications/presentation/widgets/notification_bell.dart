import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({this.color, super.key});
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<NotificationsCubit, NotificationsState, int>(
        selector: (state) => state.unreadCount,
        builder: (context, count) => IconButton(
          key: const Key('notification-bell'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          tooltip: context.tr('Notifications'),
          icon: Badge(
            key: const Key('notification-badge'),
            isLabelVisible: count > 0,
            label: Text(
              count > 99
                  ? '99+'
                  : context.tr('{value1}', {'value1': (count).toString()}),
            ),
            child: Icon(Icons.notifications_none_rounded, color: color),
          ),
        ),
      );
}
