import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

abstract interface class ProfileImagePicker {
  Future<Uint8List?> pickImage();
}

class DeviceProfileImagePicker implements ProfileImagePicker {
  DeviceProfileImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    return file?.readAsBytes();
  }
}
