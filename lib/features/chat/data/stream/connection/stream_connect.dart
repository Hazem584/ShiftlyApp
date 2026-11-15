import 'package:shiftly/core/session/feature_scope.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'stream_client_factory.dart';
import 'stream_connection_state.dart';
import 'stream_provider_configuration.dart';
import 'stream_session_issuer.dart';

Future<stream.StreamChatClient?> connectStream(
  StreamConnectionState state,
  FeatureSessionScope current,
  int generation,
) async {
  await state.closing;
  state.check(current, generation);
  if (!await streamProviderEnabled(state, current, generation)) return null;
  final auth = await issueStreamSession(state, current, generation);
  final client = createStreamClient(state, auth);
  String? first = auth['token'] as String;
  try {
    await client.connectUserWithProvider(
      stream.User(id: current.membershipId),
      (_) async {
        state.check(current, generation);
        if (first != null) {
          final token = first!;
          first = null;
          return token;
        }
        return (await issueStreamSession(state, current, generation))['token']
            as String;
      },
    );
    state.check(current, generation);
  } catch (_) {
    await client.disconnectUser(flushChatPersistence: true);
    rethrow;
  }
  state.client = client;
  state.subscription = client.on().listen((event) {
    if (state.scope == current &&
        state.generation == generation &&
        !state.events.isClosed) {
      state.events.add(event);
    }
  });
  return client;
}
