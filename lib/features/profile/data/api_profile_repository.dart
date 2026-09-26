import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/profile/data/models/profile_model.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._dio, this._activeMembership, {this.currentUser});

  final Dio _dio;
  final WorkspaceMembership? Function() _activeMembership;
  final CurrentUser? Function()? currentUser;

  @override
  Future<ManagerProfile> getProfile() async {
    try {
      final cached = currentUser?.call();
      if (cached != null) {
        return ProfileModel.fromCurrentUser(cached)
            .toPresentation(_membershipFrom(cached));
      }
      final response = await _dio.get<Object?>(ApiEndpoints.currentUser);
      final json = _json(response.data);
      final user = CurrentUser.fromJson(json);
      return ProfileModel.fromCurrentUser(user)
          .toPresentation(_membershipFrom(user));
    } catch (error) {
      throw _parse(error);
    }
  }

  @override
  Future<ManagerProfile> updateProfile({
    required String fullName,
    required String? phone,
  }) => _profileRequest(
    () => _dio.patch<Object?>(
      ApiEndpoints.profile,
      data: <String, Object?>{
        'fullName': fullName.trim(),
        'phone': phone?.trim(),
      },
    ),
  );

  @override
  Future<ManagerProfile> uploadAvatar(ProfileImageSelection image) {
    final mimeType = image.detectedMimeType;
    if (mimeType == null) {
      throw const FormatException('Unsupported avatar content');
    }
    return _profileRequest(
      () => _dio.post<Object?>(
        ApiEndpoints.avatar,
        data: FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            image.bytes,
            filename: image.fileName,
            contentType: DioMediaType.parse(mimeType),
          ),
        }),
      ),
    );
  }

  @override
  Future<ManagerProfile> deleteAvatar() =>
      _profileRequest(() => _dio.delete<Object?>(ApiEndpoints.avatar));

  Future<ManagerProfile> _profileRequest(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      return ProfileModel.fromJson(_json(response.data))
          .toPresentation(_activeMembership());
    } catch (error) {
      throw _parse(error);
    }
  }

  WorkspaceMembership? _membershipFrom(CurrentUser user) {
    final activeId = _activeMembership()?.workspace.id;
    final matching = user.memberships.where(
      (membership) => membership.workspace.id == activeId,
    );
    return matching.length == 1 ? matching.single : _activeMembership();
  }

  Map<String, Object?> _json(Object? data) {
    if (data is! Map) throw const FormatException('Invalid profile response');
    return Map<String, Object?>.from(data);
  }

  Object _parse(Object error) => ApiErrorParser.parse(
    error is DioException && error.error != null ? error.error! : error,
  );
}
