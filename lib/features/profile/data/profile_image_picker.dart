import 'package:image_picker/image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

export 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

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
