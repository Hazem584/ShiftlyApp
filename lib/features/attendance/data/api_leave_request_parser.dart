import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

Future<LeaveRequestRecord> parseLeaveRecordResponse(
  Future<Response<Object?>> Function() operation,
) => runLeaveApiRequest(() async {
  final response = await operation();
  return LeaveRequestRecord.fromJson(ApiModelParser.map(response.data));
});

LeaveRequestPage parseLeavePageResponse(Object? value) {
  final json = ApiModelParser.map(value);
  return LeaveRequestPage(
    data: ApiModelParser.list(json['data'], 'data')
        .map((item) => LeaveRequestRecord.fromJson(ApiModelParser.map(item)))
        .toList(growable: false),
    pagination: ApiPagination.fromJson(
      ApiModelParser.map(json['pagination'], 'pagination'),
    ),
  );
}

Future<T> runLeaveApiRequest<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (error) {
    throw ApiErrorParser.parse(error);
  }
}
