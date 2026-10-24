import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_cubit.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_view.dart';

class DeviceSessionsScreen extends StatelessWidget {
  const DeviceSessionsScreen({
    super.key,
    this.repository,
    required this.onCurrentSessionRevoked,
  });
  final DeviceSessionsRepository? repository;
  final Future<void> Function() onCurrentSessionRevoked;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => DeviceSessionsCubit(
      repository ?? context.read<DeviceSessionsRepository>(),
    )..load(),
    child: DeviceSessionsView(onCurrentSessionRevoked: onCurrentSessionRevoked),
  );
}
