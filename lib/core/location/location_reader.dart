import 'package:geolocator/geolocator.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/attendance_location_point.dart';

typedef AttendanceLocationReader = Future<AttendanceLocationPoint?> Function({
  required bool requiredForPunch,
});

Future<AttendanceLocationPoint?> readDeviceAttendanceLocation({
  required bool requiredForPunch,
}) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (requiredForPunch) {
        throw const ApiException(
          code: 'LOCATION_SERVICES_DISABLED',
          message: 'Turn on location services to record attendance.',
        );
      }
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (requiredForPunch) {
        throw ApiException(
          code: 'LOCATION_PERMISSION_DENIED',
          message: permission == LocationPermission.deniedForever
              ? 'Location permission is blocked in system settings.'
              : 'Allow location permission to record attendance at your workplace.',
        );
      }
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return AttendanceLocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      isMocked: position.isMocked,
    );
  } on ApiException {
    rethrow;
  } catch (_) {
    if (requiredForPunch) {
      throw const ApiException(
        code: 'LOCATION_REQUIRED',
        message: 'Could not read your GPS location. Move outdoors and retry.',
      );
    }
    return null;
  }
}
