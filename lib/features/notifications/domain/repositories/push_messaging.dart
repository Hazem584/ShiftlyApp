import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';

enum PushPermission { unsupported, unavailable, notDetermined, denied, granted }

abstract interface class PushMessaging {
  String get platform;
  Stream<PushNotice> get foreground;
  Stream<PushNotice> get opened;
  Stream<String> get tokenChanges;
  Future<PushPermission> initialize();
  Future<PushPermission> permission({bool request = false});
  Future<PushNotice?> initialNotice();
  Future<String?> token();
  Future<void> revokeToken();
  Future<void> close();
}
