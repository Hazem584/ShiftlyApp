import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedRead {
  const SavedRead({
    required this.owner,
    required this.data,
    required this.updatedAt,
  });
  final String owner;
  final Object? data;
  final DateTime updatedAt;
}

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
      final raw = _preferences?.getString(key) ?? _memory[key];
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.parse(json['updatedAt'] as String).toUtc();
      if (json['owner'] != owner ||
          now.difference(timestamp) > maxAge ||
          timestamp.isAfter(now)) {
        return null;
      }
      return SavedRead(owner: owner, data: json['data'], updatedAt: timestamp);
    } catch (_) {
      return null;
    }
  }

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

  Future<void> clearOwner(String owner) => _serialize(() async {
    for (final key in _keys().toList()) {
      try {
        final raw = _preferences?.getString(key) ?? _memory[key];
        if ((jsonDecode(raw!) as Map)['owner'] == owner) await _remove(key);
      } catch (_) {
        await _remove(key);
      }
    }
  });

  Future<void> clearUser(String userId) => _serialize(() async {
    for (final key in _keys().toList()) {
      try {
        final raw = _preferences?.getString(key) ?? _memory[key];
        if (((jsonDecode(raw!) as Map)['owner'] as String).startsWith(
          '$userId|',
        )) {
          await _remove(key);
        }
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
      return (jsonDecode(_preferences?.getString(key) ?? _memory[key]!)
              as Map)['updatedAt']
          as String;
    } catch (_) {
      return '';
    }
  }

  Future<void> _remove(String key) async {
    _memory.remove(key);
    await _preferences?.remove(key);
  }
}
