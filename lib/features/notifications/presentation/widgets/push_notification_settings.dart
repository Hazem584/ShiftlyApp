import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';

class PushNotificationSettings extends StatelessWidget {
  const PushNotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    // Isolated previews and existing feature tests do not initialize Firebase.
    final cubit = context.read<PushNotificationsCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<PushNotificationsCubit, PushNotificationsState>(
      bloc: cubit,
      builder: (context, state) => SwitchListTile(
        key: const Key('mobile-notifications-toggle'),
        contentPadding: EdgeInsets.zero,
        title: Text(context.tr('Mobile notifications')),
        subtitle: Text(
          context.tr(
            state.message ??
                switch (state.permission) {
                  PushPermission.unsupported =>
                    'Mobile notifications are available on Android and iOS.',
                  PushPermission.unavailable =>
                    'Mobile notifications are not configured on this device.',
                  PushPermission.denied => 'Allow notifications in your phone settings, then try again.',
                  _ =>
                    state.enabled
                        ? 'Receive shift, attendance and leave updates on this phone.'
                        : 'Enable alerts when Shiftly is in the background.',
                },
          ),
        ),
        value: state.enabled,
        onChanged:
            state.busy ||
                state.permission == PushPermission.unsupported ||
                state.permission == PushPermission.unavailable
            ? null
            : cubit.setEnabled,
        secondary: state.busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.notifications_active_outlined),
      ),
    );
  }
}
