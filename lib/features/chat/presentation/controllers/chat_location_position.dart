import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_media_capture.dart';

Future<Position?> acquireChatLocationPosition(ChatMediaCapture capture) async {
  final context = capture.context;
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr('Turn on location services to share a location.'),
      );
    }
    return null;
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    if (context.mounted && capture.active) {
      Fluttertoast.showToast(
        msg: context.tr(
          perm == LocationPermission.deniedForever
              ? 'Location permission is blocked in system settings.'
              : 'Location permission was denied.',
        ),
      );
    }
    return null;
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
}
