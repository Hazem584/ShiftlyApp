import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:stream_chat_persistence/stream_chat_persistence.dart'
    as persistence;

class StreamChatConnection {
  StreamChatConnection(this.api, {this.clientFactory, this.persist = true});
  final stream.StreamChatClient Function(String)? clientFactory;
  final bool persist;
  final Dio api;
  FeatureSessionScope? _scope;
  FeatureSessionScope? get scope => _scope;
  stream.StreamChatClient? _client;
  Future<stream.StreamChatClient?>? _connecting;
  Future<void> _closing = Future.value();
  final _events = StreamController<stream.Event>.broadcast();
  Stream<stream.Event> get events => _events.stream;
  StreamSubscription<stream.Event>? _subscription;
  final _watched = <String>{};
  final _watching = <String, Future<stream.Channel>>{};
  int _generation = 0;
  void bind(FeatureSessionScope? next) {
    if (_scope == next) return;
    _generation++;
    _scope = next;
    final previous = _client;
    _client = null;
    _connecting = null;
    _watched.clear();
    _watching.clear();
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (previous != null) {
      _closing = _closing
          .then((_) => previous.disconnectUser(flushChatPersistence: true))
          .catchError((Object _) {});
    }
  }

  void _check(FeatureSessionScope expected, int generation) {
    if (_scope != expected || generation != _generation) {
      throw StateError('Chat session changed.');
    }
  }

  Future<stream.StreamChatClient?> clientFor(String workspaceId) {
    final current = _scope;
    if (current == null || current.workspaceId != workspaceId) {
      throw StateError('Chat session is no longer active.');
    }
    final generation = _generation;
    return _connecting ??= _connect(current, generation).catchError((
      Object error,
    ) {
      if (_generation == generation) _connecting = null;
      throw error;
    });
  }

  Future<stream.StreamChatClient?> _connect(
    FeatureSessionScope current,
    int generation,
  ) async {
    await _closing;
    _check(current, generation);
    Map data;
    try {
      data =
          (await api.get<Object?>(
                '/workspaces/${current.workspaceId}/chat/stream/configuration',
              )).data
              as Map;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
    _check(current, generation);
    if (data['enabled'] == false) return null;
    if (data['enabled'] != true) {
      throw const FormatException('Invalid chat provider configuration');
    }
    Future<Map> session() async {
      _check(current, generation);
      final value =
          (await api.post<Object?>(
                '/workspaces/${current.workspaceId}/chat/stream/session',
              )).data
              as Map;
      _check(current, generation);
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

    final auth = await session();
    final client =
        clientFactory?.call(auth['apiKey'] as String) ??
        stream.StreamChatClient(
          auth['apiKey'] as String,
          logLevel: stream.Level.OFF,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
        );
    if (persist && !kIsWeb) {
      client.chatPersistenceClient = persistence.StreamChatPersistenceClient(
        logLevel: stream.Level.OFF,
        connectionMode: persistence.ConnectionMode.background,
      );
    }
    String? first = auth['token'] as String;
    try {
      await client.connectUserWithProvider(
        stream.User(id: current.membershipId),
        (_) async {
          _check(current, generation);
          if (first != null) {
            final token = first!;
            first = null;
            return token;
          }
          return (await session())['token'] as String;
        },
      );
      _check(current, generation);
    } catch (_) {
      await client.disconnectUser(flushChatPersistence: true);
      rethrow;
    }
    _client = client;
    _subscription = client.on().listen((event) {
      if (_scope == current && _generation == generation && !_events.isClosed) {
        _events.add(event);
      }
    });
    return client;
  }

  Future<stream.Channel> channel(String workspaceId, String groupId) async {
    final client = await clientFor(workspaceId);
    if (client == null) throw StateError('Stream is not enabled.');
    final existing = client.channel('shiftly', id: groupId);
    if (_watched.contains(groupId)) return existing;
    return _watching
        .putIfAbsent(groupId, () async {
          final current = _scope!, generation = _generation;
          await api.post<Object?>(
            '/workspaces/$workspaceId/chat/stream/groups/$groupId',
          );
          _check(current, generation);
          await existing.watch();
          _check(current, generation);
          _watched.add(groupId);
          return existing;
        })
        .whenComplete(() => _watching.remove(groupId));
  }

  Future<Map<String, stream.Channel>> channels(
    String workspaceId,
    Set<String> allowed,
  ) async {
    final client = await clientFor(workspaceId);
    if (client == null) return {};
    final current = _scope!, generation = _generation;
    final found = <String, stream.Channel>{};
    if (allowed.every((id) => _watched.contains(id))) {
      return {for (final id in allowed) id: client.channel('shiftly', id: id)};
    }

    for (var offset = 0; ; offset += 30) {
      final list = await client.queryChannelsOnline(
        filter: stream.Filter.and([
          stream.Filter.equal('type', 'shiftly'),
          stream.Filter.equal('shiftly_workspace_id', workspaceId),
          stream.Filter.in_('members', [current.membershipId]),
        ]),
        paginationParams: stream.PaginationParams(limit: 30, offset: offset),
        messageLimit: 1,
        memberLimit: 0,
      );
      _check(current, generation);
      for (final channel in list) {
        if (allowed.contains(channel.id)) {
          found[channel.id!] = channel;
          _watched.add(channel.id!);
        }
      }
      if (list.length < 30) break;
    }
    for (final id in allowed.difference(found.keys.toSet())) {
      found[id] = await channel(workspaceId, id);
    }
    return found;
  }

  Future<void> dispose() async {
    bind(null);
    await _closing;
    await _events.close();
  }
}
