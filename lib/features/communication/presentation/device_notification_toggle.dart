import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';

class DeviceNotificationToggle extends StatelessWidget {
  const DeviceNotificationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PushNotificationsCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<PushNotificationsCubit, PushNotificationsState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.permission == PushPermission.unsupported) {
          return const SizedBox.shrink();
        }
        final subtitle =
            state.message ??
            (state.permission == PushPermission.denied
                ? 'Allow notifications in your phone settings, then try again.'
                : 'Chat messages and task notifications');
        return Card(
          child: SwitchListTile(
            key: const Key('enable-notifications'),
            title: Text(context.tr('Device notification permissions')),
            subtitle: Text(context.tr(subtitle)),
            value: state.enabled,
            onChanged:
                state.busy || state.permission == PushPermission.unavailable
                ? null
                : cubit.setEnabled,
          ),
        );
      },
    );
  }
}
