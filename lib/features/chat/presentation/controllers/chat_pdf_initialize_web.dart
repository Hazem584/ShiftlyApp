import 'dart:js_interop';

@JS('shiftlyPdfReady')
external JSPromise<JSAny?>? get _ready;

Future<void> initializeChatPdf() async {
  // The module loader can finish after Flutter bootstraps on a fast warm start.
  for (var attempt = 0; attempt < 100 && _ready == null; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  final ready = _ready;
  if (ready == null) throw StateError('PDF renderer unavailable');
  await ready.toDart.timeout(const Duration(seconds: 20));
}
