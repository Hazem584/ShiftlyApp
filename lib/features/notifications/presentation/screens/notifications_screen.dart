import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/communication/presentation/notification_permission_screen.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_list_content.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen_actions.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsCubit>().load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      CommunicationAppearance(child: Builder(builder: _build));

  Widget _build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Inbox')),
      actions: [
        IconButton(
          key: const Key('notification-permission-settings'),
          tooltip: context.tr('Stay informed'),
          onPressed: () => openCommunicationPage(
            context,
            const NotificationPermissionScreen(),
          ),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, s) => TextButton(
            key: const Key('mark-all-notifications-read'),
            onPressed: s.unreadCount == 0 || s.markingAll
                ? null
                : () => markAllNotificationsRead(context),
            child: Text(
              context.tr(s.markingAll ? 'Saving…' : 'Mark all as read'),
            ),
          ),
        ),
      ),
    ),
    body: BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, s) => s.initialLoading
          ? const AppContentLoading()
          : s.notifications.isEmpty && s.failure != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: context.tr('Could not load notifications'),
              message: s.failure!.message,
              action: FilledButton(
                onPressed: context.read<NotificationsCubit>().load,
                child: Text(context.tr('Retry')),
              ),
            )
          : NotificationsListContent(
              state: s,
              unreadOnly: _unreadOnly,
              onUnreadFilterChanged: (v) => setState(() => _unreadOnly = v),
              onOpen: (item) => openNotificationItem(context, item),
              onDelete: (item) => confirmAndDeleteNotification(context, item),
            ),
    ),
  );
}
