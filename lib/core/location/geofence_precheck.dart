import 'dart:math' as math;

import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/models/attendance_location_point.dart';
import 'package:shiftly/core/models/workspace_work_location.dart';

void validateGeofenceBeforeSelfie({
  required String geofenceMode,
  required AttendanceLocationPoint? location,
  required List<WorkspaceWorkLocation> workLocations,
  String? requiredWorkLocationId,
}) {
  if (geofenceMode != 'ENFORCE') return;
  if (location == null) {
    throw const ApiException(
      code: 'LOCATION_REQUIRED',
      message:
          'Turn on location services to record attendance at this workspace.',
      kind: FailureKind.validation,
    );
  }
  if (location.isMocked) {
    throw const ApiException(
      code: 'MOCK_LOCATION_DETECTED',
      message: 'Disable mock location apps before recording attendance.',
      kind: FailureKind.validation,
    );
  }
  if ((location.accuracyMeters ?? 0) > 150) {
    throw const ApiException(
      code: 'LOCATION_ACCURACY_TOO_LOW',
      message:
          'GPS signal is too weak. Move near a window or outdoors and retry.',
      kind: FailureKind.validation,
    );
  }
  final active = workLocations.where((l) => l.active).toList(growable: false);
  if (active.isEmpty) return;
  final pinned = requiredWorkLocationId == null
      ? const <WorkspaceWorkLocation>[]
      : active.where((l) => l.id == requiredWorkLocationId).toList();
  final targets = pinned.isNotEmpty ? pinned : active;
  var bestDistance = double.infinity;
  WorkspaceWorkLocation? bestTarget;
  for (final target in targets) {
    final d = haversineDistanceMeters(
      location.latitude,
      location.longitude,
      target.latitude,
      target.longitude,
    );
    if (d < bestDistance) {
      bestDistance = d;
      bestTarget = target;
    }
  }
  if (bestTarget != null && bestDistance.round() > bestTarget.radiusMeters) {
    throw const ApiException(
      code: 'OUTSIDE_WORK_LOCATION',
      message: 'You are outside the allowed workplace area. Move closer to your work location and try again.',
      kind: FailureKind.validation,
    );
  }
}

double haversineDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
