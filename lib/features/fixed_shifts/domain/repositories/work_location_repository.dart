import 'package:shiftly/core/models/workspace_work_location.dart';

export 'package:shiftly/core/models/attendance_location_point.dart';
export 'package:shiftly/core/models/workspace_work_location.dart';

abstract interface class WorkLocationRepository {
  Future<(String geofenceMode, String selfieMode)> getWorkspacePolicies(
    String workspaceId,
  );
  Future<(String geofenceMode, String selfieMode)> updateWorkspacePolicies(
    String workspaceId, {
    String? geofenceMode,
    String? selfieMode,
  });
  Future<List<WorkspaceWorkLocation>> list(
    String workspaceId, {
    bool includeArchived = false,
  });
  Future<WorkspaceWorkLocation> create(
    String workspaceId, {
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  });
  Future<WorkspaceWorkLocation> update(
    String workspaceId,
    String locationId, {
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  });
  Future<WorkspaceWorkLocation> archive(String workspaceId, String locationId);
}
