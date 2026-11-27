import 'package:dio/dio.dart';

String savedReadRequestUrl(RequestOptions options) {
  final sorted = Map.fromEntries(
    options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
  return options.uri
      .replace(
        queryParameters: sorted.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      )
      .toString();
}
