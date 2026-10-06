part of '../../current_user.dart';

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.code,
    required this.timezone,
  });

  final String id;
  final String name;
  final String code;
  final String timezone;

  factory Workspace.fromJson(Map<String, Object?> json) => Workspace(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
    code: _requiredString(json, 'code'),
    timezone: _requiredString(json, 'timezone'),
  );
}
