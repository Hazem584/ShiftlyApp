import 'dart:typed_data';

import 'package:shiftly/core/session/feature_scope.dart';

class ChatDocumentBytes {
  Future<Uint8List>? _request;
  FeatureSessionScope? _session;

  void clear() => _request = null;

  Future<Uint8List> load(
    FeatureSessionScope session,
    Future<Uint8List> Function() fetch,
  ) {
    if (_session != session) {
      clear();
      _session = session;
    }
    return _request ??= fetch().catchError((Object error) {
      clear();
      throw error;
    });
  }
}
