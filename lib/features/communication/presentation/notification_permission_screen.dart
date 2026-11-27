import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';

import 'communication_page.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PushNotificationsCubit?>();
    return cubit == null
        ? _buildPage(context, null, const PushNotificationsState())
        : BlocBuilder<PushNotificationsCubit, PushNotificationsState>(
            bloc: cubit,
            builder: (ctx, state) => _buildPage(ctx, cubit, state),
          );
  }

  Widget _buildPage(
    BuildContext context,
    PushNotificationsCubit? cubit,
    PushNotificationsState state,
  ) {
    final available =
        !kIsWeb &&
        cubit != null &&
        state.permission != PushPermission.unsupported &&
        state.permission != PushPermission.unavailable;
    final label = state.busy
        ? 'Saving…'
        : state.enabled
        ? 'Notifications enabled'
        : 'Enable notifications';
    return CommunicationPage(
      title: 'Stay informed',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const Key('enable-notifications'),
            onPressed: available && !state.busy && !state.enabled
                ? () => cubit.setEnabled(true)
                : null,
            child: Text(context.tr(label)),
          ),
          TextButton(
            onPressed: state.busy ? null : () => Navigator.pop(context),
            child: Text(context.tr('Not now')),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.notifications_active_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('Keep up with your team.'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(
              'Allow notifications for messages, announcements and review decisions. You can change permission in device settings.',
            ),
          ),
          const SizedBox(height: 32),
          if (!available)
            Text(
              context.tr(
                kIsWeb
                    ? 'Updates appear here while you use Shiftly. Background alerts are available in the mobile app.'
                    : 'Mobile notifications are not configured on this device.',
              ),
            ),
          if (state.message != null) Text(context.tr(state.message!)),
          if (state.permission == PushPermission.denied)
            Text(
              context.tr(
                'Allow notifications in your phone settings, then try again.',
              ),
            ),
        ],
      ),
    );
  }
}
