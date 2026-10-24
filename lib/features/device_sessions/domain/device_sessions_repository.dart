class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    required this.isCurrent,
    required this.isFirst,
  });
  final String id;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool isCurrent;
  final bool isFirst;
}

class DeviceSessionsPage {
  const DeviceSessionsPage(this.items, {required this.hasNext});
  final List<DeviceSession> items;
  final bool hasNext;
}

abstract interface class DeviceSessionsRepository {
  Future<void> registerCurrent();
  Future<DeviceSessionsPage> load({int page = 1});
  Future<bool> revoke(String sessionId);
  Future<void> revokeAll();
}
