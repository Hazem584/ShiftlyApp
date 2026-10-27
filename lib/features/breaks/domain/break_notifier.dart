abstract interface class BreakNotifier {
  /// Returns false when this device cannot deliver a background notification.
  Future<bool> scheduleBreak(DateTime end, {required bool arabic});
  Future<void> cancelBreak();
}
