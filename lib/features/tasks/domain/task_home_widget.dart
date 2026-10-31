import 'personal_task.dart';

abstract interface class TaskHomeWidget {
  bool get isSupported;
  Future<bool> requestPin();
  Future<void> publish(String ownerId, TaskPage page, DateTime now);
  Future<void> clear();
}

class NoTaskHomeWidget implements TaskHomeWidget {
  const NoTaskHomeWidget();
  @override
  bool get isSupported => false;
  @override
  Future<bool> requestPin() async => false;
  @override
  Future<void> publish(String ownerId, TaskPage page, DateTime now) async {}
  @override
  Future<void> clear() async {}
}
