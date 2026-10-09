import 'package:shiftly/features/auth/domain/entities/current_user_parsers.dart';

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
    id: currentUserRequiredString(json, 'id'),
    name: currentUserRequiredString(json, 'name'),
    code: currentUserRequiredString(json, 'code'),
    timezone: currentUserRequiredString(json, 'timezone'),
  );
}
