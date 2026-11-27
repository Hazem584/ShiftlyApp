import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_cubit.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_session_revoke_dialog.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_list.dart';

class DeviceSessionsView extends StatelessWidget {
  const DeviceSessionsView({super.key, required this.onCurrentSessionRevoked});
  final Future<void> Function() onCurrentSessionRevoked;

  Future<void> _revoke(BuildContext context, DeviceSession? target) async {
    final confirmed = await showRevokeDeviceSessionDialog(context, target);
    if (confirmed != true || !context.mounted) return;
    final current = await context.read<DeviceSessionsCubit>().revoke(target);
    if (current == true) await onCurrentSessionRevoked();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DeviceSessionsCubit, DeviceSessionsState>(
    builder: (context, state) {
      final blocked = state.busy || state.loading;
      final cubit = context.read<DeviceSessionsCubit>();
      return CommunicationPage(
        title: 'Devices and sessions',
        footer: OutlinedButton.icon(
          key: const Key('logout-all-devices'),
          onPressed: blocked || state.items.isEmpty
              ? null
              : () => _revoke(context, null),
          icon: const Icon(Icons.logout),
          label: Text(context.tr('Sign out all devices')),
        ),
        child: DeviceSessionsList(
          state: state,
          blocked: blocked,
          onRefresh: cubit.load,
          onLoadMore: () => cubit.load(more: true),
          onRevoke: (device) => _revoke(context, device),
        ),
      );
    },
  );
}
