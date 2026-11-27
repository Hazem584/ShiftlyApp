import 'package:image_picker/image_picker.dart';
import 'package:shiftly/core/location/native_selfie_capture.dart'
    if (dart.library.js_interop) 'package:shiftly/core/location/browser_selfie_capture.dart';

typedef AttendanceSelfieReader = Future<String?> Function({
  required bool requiredForPunch,
});

Future<String?> captureFrontCameraSelfieBase64({
  required bool requiredForPunch,
  ImagePicker? picker,
}) => platformCaptureFrontCameraSelfieBase64(
  requiredForPunch: requiredForPunch,
  picker: picker,
);
