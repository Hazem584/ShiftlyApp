import 'dart:convert';

import 'saved_read.dart';

SavedRead? decodeSavedRead(
  String? raw,
  String owner,
  DateTime now,
  Duration maxAge,
) {
  if (raw == null) return null;
  try {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final timestamp = DateTime.parse(data['updatedAt'] as String).toUtc();
    if (data['owner'] != owner ||
        now.difference(timestamp) > maxAge ||
        timestamp.isAfter(now)) {
      return null;
    }
    return SavedRead(owner: owner, data: data['data'], updatedAt: timestamp);
  } catch (_) {
    return null;
  }
}
