import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class ManagerPointsAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object? response = [];
  int status = 200;
  Object? Function(RequestOptions)? respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond?.call(options) ?? response),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
