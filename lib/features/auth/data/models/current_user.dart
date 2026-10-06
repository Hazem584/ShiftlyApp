part 'parts/current_user/workspace_role.dart';
part 'parts/current_user/membership_status.dart';
part 'parts/current_user/workspace.dart';
part 'parts/current_user/workspace_membership.dart';
part 'parts/current_user/current_user.dart';

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Invalid $key');
  return value;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('Invalid $key');
  return parsed.toUtc();
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed.toUtc();
}
