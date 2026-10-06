import 'package:equatable/equatable.dart';

part 'parts/chat_models/chat_sender.dart';
part 'parts/chat_models/chat_message.dart';
part 'parts/chat_models/chat_attachment.dart';
part 'parts/chat_models/chat_location.dart';
part 'parts/chat_models/chat_upload_authorization.dart';
part 'parts/chat_models/chat_media_url.dart';
part 'parts/chat_models/chat_member.dart';
part 'parts/chat_models/chat_group.dart';
part 'parts/chat_models/chat_message_page.dart';

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

String chatUuid(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || !_uuid.hasMatch(value)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? chatOptionalUuid(Object? value) {
  if (value == null) return null;
  if (value is! String || !_uuid.hasMatch(value)) {
    throw const FormatException('Invalid UUID');
  }
  return value;
}

Map<String, Object?> chatMap(Object? value, [String label = 'object']) {
  if (value is! Map) throw FormatException('Invalid $label');
  return Map<String, Object?>.from(value);
}

List<Object?> chatList(Object? value, [String label = 'list']) {
  if (value is! List) throw FormatException('Invalid $label');
  return value;
}

String _text(Map<String, Object?> json, String key, {bool empty = false}) {
  final value = json[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('Invalid $key');
  }
  return value;
}

String? _optionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

bool _validStoragePath(Object? value) {
  if (value is! String ||
      value.trim() != value ||
      value.isEmpty ||
      value.startsWith('/') ||
      value.endsWith('/') ||
      value.contains(r'\')) {
    return false;
  }
  try {
    return value.split('/').every((segment) {
      final decoded = Uri.decodeComponent(segment);
      return decoded.isNotEmpty &&
          decoded != '.' &&
          decoded != '..' &&
          !decoded.contains('/') &&
          !decoded.contains(r'\');
    });
  } on FormatException {
    return false;
  }
}

int _count(Object? value, String label) {
  if (value is! int || value < 0) throw FormatException('Invalid $label');
  return value;
}

DateTime _date(Map<String, Object?> json, String key) {
  final value = json[key];
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw FormatException('Invalid $key');
  return date.toUtc();
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  final date = value is String ? DateTime.tryParse(value) : null;
  if (date == null) throw const FormatException('Invalid timestamp');
  return date.toUtc();
}
