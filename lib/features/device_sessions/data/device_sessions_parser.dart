import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

DeviceSessionsPage parseDeviceSessionsPage(Map<String, dynamic> data) {
  final items = (data['items'] as List)
      .map((value) {
        final row = Map<String, dynamic>.from(value as Map);
        final rawName = row['deviceName'] as String?;
        return DeviceSession(
          id: row['id'] as String,
          deviceName: rawName?.trim().isNotEmpty == true
              ? rawName!
              : 'Unknown device',
          platform: row['platform'] as String? ?? '',
          osVersion: row['osVersion'] as String? ?? '',
          appVersion: row['appVersion'] as String? ?? '',
          createdAt: DateTime.parse(row['createdAt'] as String),
          lastSeenAt: DateTime.parse(row['lastSeenAt'] as String),
          isCurrent: row['isCurrent'] == true,
          isFirst: row['isFirst'] == true,
        );
      })
      .toList(growable: false);
  return DeviceSessionsPage(items, hasNext: data['hasNext'] == true);
}
