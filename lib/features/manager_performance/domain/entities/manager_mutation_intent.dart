import 'dart:convert';

class ManagerMutationIntent {
  ManagerMutationIntent({
    required this.resource,
    required Map<String, Object?> payload,
    this.target,
    this.patch = false,
  }) : payload = Map.unmodifiable(payload);
  final String resource;
  final String? target;
  final bool patch;
  final Map<String, Object?> payload;
  String encode() => jsonEncode({
    'resource': resource,
    'target': target,
    'patch': patch,
    'payload': payload,
  });
  factory ManagerMutationIntent.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return ManagerMutationIntent(
      resource: json['resource'] as String,
      target: json['target'] as String?,
      patch: json['patch'] == true,
      payload: Map<String, Object?>.from(json['payload'] as Map),
    );
  }
  bool get hasUuid => payload.keys.any((key) => key.startsWith('client'));
}
