import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

Future<AttendanceRecordApi> parseAttendanceRecordResponse(
  Future<Response<Object?>> Function() operation,
) => runAttendanceApiRequest(() async {
  final response = await operation();
  return AttendanceRecordApi.fromJson(ApiModelParser.map(response.data));
});

AttendancePage parseAttendancePageResponse(Object? value) {
  final json = ApiModelParser.map(value);
  return AttendancePage(
    data: ApiModelParser.list(json['data'], 'data')
        .map((item) => AttendanceRecordApi.fromJson(ApiModelParser.map(item)))
        .toList(growable: false),
    pagination: ApiPagination.fromJson(
      ApiModelParser.map(json['pagination'], 'pagination'),
    ),
  );
}

Future<T> runAttendanceApiRequest<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (error) {
    throw ApiErrorParser.parse(error);
  }
}
