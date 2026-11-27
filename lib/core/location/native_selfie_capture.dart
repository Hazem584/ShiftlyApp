import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';

Future<String?> platformCaptureFrontCameraSelfieBase64({
  required bool requiredForPunch,
  ImagePicker? picker,
}) async {
  try {
    final file = await (picker ?? ImagePicker()).pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 65,
      maxWidth: 640,
      maxHeight: 640,
    );
    if (file == null) {
      if (requiredForPunch) {
        throw const ApiException(
          code: 'SELFIE_REQUIRED',
          message: 'Take a front-camera selfie to clock in at this workspace.',
          kind: FailureKind.validation,
        );
      }
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      if (requiredForPunch) {
        throw const ApiException(
          code: 'SELFIE_INVALID',
          message: 'Could not read the captured selfie photo. Please retry.',
          kind: FailureKind.validation,
        );
      }
      return null;
    }
    return base64Encode(bytes);
  } on ApiException {
    rethrow;
  } catch (_) {
    if (requiredForPunch) {
      throw const ApiException(
        code: 'SELFIE_CAMERA_UNAVAILABLE',
        message:
            'Allow camera access and take a front-camera selfie to clock in.',
        kind: FailureKind.validation,
      );
    }
    return null;
  }
}
