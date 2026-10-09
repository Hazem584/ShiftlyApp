import 'package:shiftly/features/profile/domain/entities/profile_image_selection.dart';

export 'package:shiftly/features/profile/domain/entities/profile_image_selection.dart';

abstract interface class ProfileImagePicker {
  Future<ProfileImageSelection?> pickImage();
}
