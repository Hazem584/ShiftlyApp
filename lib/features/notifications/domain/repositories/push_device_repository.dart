import 'package:shiftly/features/notifications/domain/entities/notification_record.dart';

abstract interface class PushDeviceRepository {
  Future<void> register({
    required String installationId,
    required String token,
    required String platform,
  });
  Future<void> unregister(String installationId);
  Future<NotificationRecord> getNotification(String notificationId);
}
