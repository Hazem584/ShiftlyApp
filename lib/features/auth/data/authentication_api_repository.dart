import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_endpoints.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';

class AuthenticationApiRepository implements AuthenticationRepository {
  AuthenticationApiRepository(this._dio);

  final Dio _dio;

  @override
  Future<CurrentUser> loadCurrentUser() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.currentUser);
      final data = response.data;
      if (data is! Map) throw const FormatException('Invalid current user');
      return CurrentUser.fromJson(Map<String, Object?>.from(data));
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {
    final body = <String, String>{
      if (fullName?.trim().isNotEmpty == true) 'fullName': fullName!.trim(),
      if (phone?.trim().isNotEmpty == true) 'phone': phone!.trim(),
    };
    try {
      await _dio.post<Object?>(ApiEndpoints.bootstrap, data: body);
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
