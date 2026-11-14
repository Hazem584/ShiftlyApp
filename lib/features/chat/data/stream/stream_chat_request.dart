import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

Future<T> streamChatRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } catch (error) {
    if (error is stream.StreamChatNetworkError) {
      final status = error.statusCode;
      throw ApiException(
        statusCode: status,
        code: 'STREAM_CHAT_REQUEST_FAILED',
        kind: status == 401
            ? FailureKind.authentication
            : status == 403 || status == 404
            ? FailureKind.authorization
            : status == null
            ? FailureKind.network
            : status >= 500 || status == 429
            ? FailureKind.server
            : FailureKind.validation,
        message: status == 403 || status == 404
            ? 'This chat is no longer available.'
            : status == 401
            ? 'Your session has expired. Sign in again.'
            : 'Could not connect to chat. Please retry.',
      );
    }
    throw ApiErrorParser.parse(error);
  }
}
