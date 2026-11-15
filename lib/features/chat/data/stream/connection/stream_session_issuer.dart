import 'package:shiftly/core/session/feature_scope.dart';

import 'stream_connection_state.dart';

Future<Map> issueStreamSession(
  StreamConnectionState state,
  FeatureSessionScope current,
  int generation,
) async {
  state.check(current, generation);
  final value =
      (await state.api.post<Object?>(
            '/workspaces/${current.workspaceId}/chat/stream/session',
          )).data
          as Map;
  state.check(current, generation);
  if (value['userId'] != current.membershipId ||
      value['workspaceId'] != current.workspaceId ||
      value['channelType'] != 'shiftly' ||
      value['enabled'] != true ||
      value['token'] is! String ||
      value['apiKey'] is! String) {
    throw const FormatException('Invalid Stream session');
  }
  return value;
}
