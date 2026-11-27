import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class DeviceSessionsState {
  const DeviceSessionsState({
    this.items = const [],
    this.loading = false,
    this.busy = false,
    this.hasNext = false,
    this.error,
  });
  final List<DeviceSession> items;
  final bool loading;
  final bool busy;
  final bool hasNext;
  final String? error;
}
