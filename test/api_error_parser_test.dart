import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/error/failure.dart';

DioException _error({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  Object? data,
  Map<String, List<String>> headers = const {},
}) {
  final request = RequestOptions(path: '/auth/me');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response<Object?>(
            requestOptions: request,
            statusCode: status,
            data: data,
            headers: Headers.fromMap(headers),
          ),
  );
}

void main() {
  test('parses string backend error and preserves requestId', () {
    final result = ApiErrorParser.parse(
      _error(
        status: 401,
        data: {
          'statusCode': 401,
          'code': 'UNAUTHORIZED',
          'message': 'Authentication required',
          'requestId': 'request-1',
          'path': '/api/v1/auth/me',
        },
      ),
    );
    expect(result.statusCode, 401);
    expect(result.requestId, 'request-1');
    expect(result.path, '/api/v1/auth/me');
    expect(result.kind, FailureKind.authentication);
  });

  test('parses validation arrays', () {
    final result = ApiErrorParser.parse(
      _error(
        status: 400,
        data: {
          'code': 'BAD_REQUEST',
          'message': ['email must be valid', 'password is required'],
        },
      ),
    );
    expect(result.validationMessages, hasLength(2));
    expect(result.message, 'email must be valid');
  });

  test('handles plain text 502 without exposing proxy body', () {
    final result = ApiErrorParser.parse(
      _error(status: 502, data: '<html>private proxy detail</html>'),
    );
    expect(result.message, contains('temporarily unavailable'));
    expect(result.message, isNot(contains('private proxy')));
  });

  test('maps timeout, network, 429 and response request id', () {
    expect(
      ApiErrorParser.parse(_error(type: DioExceptionType.receiveTimeout)).kind,
      FailureKind.timeout,
    );
    expect(
      ApiErrorParser.parse(_error(type: DioExceptionType.connectionError)).kind,
      FailureKind.network,
    );
    expect(
      ApiErrorParser.parse(_error(status: 429)).message,
      contains('Too many'),
    );
    expect(
      ApiErrorParser.parse(
        _error(
          status: 500,
          headers: {
            'x-request-id': ['header-id'],
          },
        ),
      ).requestId,
      'header-id',
    );
  });
}
