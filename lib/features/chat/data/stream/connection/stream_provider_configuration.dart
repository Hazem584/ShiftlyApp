import 'package:dio/dio.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import 'stream_connection_state.dart';

Future<bool> streamProviderEnabled(
  StreamConnectionState state,
  FeatureSessionScope current,
  int generation,
) async {
  Map data;
  try {
    data =
        (await state.api.get<Object?>(
              '/workspaces/${current.workspaceId}/chat/stream/configuration',
            )).data
            as Map;
  } on DioException catch (error) {
    if (error.response?.statusCode == 404) return false;
    rethrow;
  }
  state.check(current, generation);
  if (data['enabled'] == false) return false;
  if (data['enabled'] != true) {
    throw const FormatException('Invalid chat provider configuration');
  }
  return true;
}
