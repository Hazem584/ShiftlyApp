import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_read.dart';
import 'saved_read_decoder.dart';

export 'saved_read.dart';

/// Bounded, read-only snapshots. Credentials and mutation bodies are never saved.
class SavedReadStore {
  SavedReadStore([this._preferences]);
  final SharedPreferences? _preferences;
  final _memory = <String, String>{};
  Future<void> _writes = Future<void>.value();
  static const _prefix = 'saved.read.v1.';
  static const maxEntries = 64;
  static const maxBytes = 400000;
  static const maxAge = Duration(days: 7);

  String key(String owner, String url) =>
      '$_prefix${sha256.convert(utf8.encode('$owner|$url'))}';

  SavedRead? read(String key, String owner, DateTime now) {
    try {
      return decodeSavedRead(_raw(key), owner, now, maxAge);
    } catch (_) {
      return null;
    }
  }

  String? _raw(String key) => _preferences?.getString(key) ?? _memory[key];

  Future<void> write(String key, SavedRead value) => _serialize(() async {
    final raw = jsonEncode({
      'owner': value.owner,
      'updatedAt': value.updatedAt.toIso8601String(),
      'data': value.data,
    });
    if (utf8.encode(raw).length > maxBytes) return;
    if (_preferences case final preferences?) {
      await preferences.setString(key, raw);
    } else {
      _memory[key] = raw;
    }
    final keys = _keys().toList()
      ..sort((a, b) => _timestamp(a).compareTo(_timestamp(b)));
    for (final key in keys.take(
      (keys.length - maxEntries).clamp(0, maxEntries),
    )) {
      await _remove(key);
    }
  });

  Future<void> remove(String key) => _serialize(() => _remove(key));

  Future<void> clearOwner(String owner) =>
      _clearMatching((value) => value == owner);

  Future<void> clearWorkspace(String userId, String workspaceId) =>
      _clearMatching((owner) => owner.startsWith('$userId|$workspaceId|'));

  Future<void> clearUser(String userId) =>
      _clearMatching((owner) => owner.startsWith('$userId|'));

  Future<void> _clearMatching(bool Function(String) matches) =>
      _serialize(() async {
        for (final key in _keys().toList()) {
          try {
            final raw = _raw(key);
            final owner = (jsonDecode(raw!) as Map)['owner'] as String;
            if (matches(owner)) await _remove(key);
          } catch (_) {
            await _remove(key);
          }
        }
      });

  Future<void> _serialize(Future<void> Function() operation) {
    // A disk failure must not turn a successful API read into a failed request.
    _writes = _writes.then((_) => operation()).catchError((Object _) {});
    return _writes;
  }

  Iterable<String> _keys() => (_preferences?.getKeys() ?? _memory.keys.toSet())
      .where((key) => key.startsWith(_prefix));
  String _timestamp(String key) {
    try {
      return (jsonDecode(_raw(key)!) as Map)['updatedAt'] as String;
    } catch (_) {
      return '';
    }
  }

  Future<void> _remove(String key) async {
    _memory.remove(key);
    await _preferences?.remove(key);
  }
}
