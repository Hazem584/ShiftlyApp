import 'package:equatable/equatable.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

class WorkspaceWorkLocation extends Equatable {
  const WorkspaceWorkLocation({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.active = true,
  });

  final String id;
  final String workspaceId;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool active;

  factory WorkspaceWorkLocation.fromJson(
    Map<String, Object?> json, {
    String fallbackWorkspaceId = '',
  }) => WorkspaceWorkLocation(
    id: ApiModelParser.string(json, 'id'),
    workspaceId:
        ApiModelParser.optionalString(json['workspaceId']) ??
        fallbackWorkspaceId,
    name: ApiModelParser.string(json, 'name'),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radiusMeters: ApiModelParser.optionalInteger(json['radiusMeters']) ?? 100,
    active: json['active'] is bool
        ? json['active'] as bool
        : json['archivedAt'] == null,
  );

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    name,
    latitude,
    longitude,
    radiusMeters,
    active,
  ];
}
