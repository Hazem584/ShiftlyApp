class ChatUploadCancellation {
  bool _cancelled = false;
  void Function()? _handler;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _handler?.call();
  }

  void bind(void Function() handler) {
    _handler = handler;
    if (_cancelled) handler();
  }

  void unbind() => _handler = null;
}
