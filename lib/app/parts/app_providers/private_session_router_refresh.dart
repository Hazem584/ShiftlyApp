part of '../../app_providers.dart';

class _SessionRouterRefresh extends ChangeNotifier {
  _SessionRouterRefresh(SessionCoordinator coordinator) {
    _subscription = coordinator.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
