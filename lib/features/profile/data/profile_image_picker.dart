import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

abstract interface class ProfileImagePicker {
  Future<ProfileImageSelection?> pickImage();
}

class ProfileImageSelection {
  const ProfileImageSelection({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  String? get detectedMimeType {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}

class DeviceProfileImagePicker implements ProfileImagePicker {
  DeviceProfileImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<ProfileImageSelection?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file == null) return null;
    return ProfileImageSelection(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );
  }
}
