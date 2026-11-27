import 'package:dio/dio.dart';
import 'package:shiftly/core/monitoring/release_policy.dart';

Future<Map<Object?, Object?>?> fetchReleaseResponse(
  Dio client,
  String platform,
  int installedBuild,
) async {
  final response = await client.get<Object?>(
    '/platform/release',
    queryParameters: {
      'platform': platform,
      'channel': releaseChannel,
      'build': installedBuild,
    },
  );
  final data = response.data;
  return data is Map ? data : null;
}
