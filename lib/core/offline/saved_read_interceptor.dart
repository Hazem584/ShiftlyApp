import 'package:dio/dio.dart';

import 'read_sync_cubit.dart';
import 'read_sync_state.dart';
import 'saved_read_policy.dart';
import 'saved_read_store.dart';

class SavedReadInterceptor extends Interceptor {
  SavedReadInterceptor(
    this.sync, {
    required this.hasSession,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final ReadSyncCubit sync;
  final bool Function() hasSession;
  final DateTime Function() _now;
  static const _context = 'savedReadContext';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra.containsKey(_context)) {
      handler.next(options);
      return;
    }
    final owner = sync.owner;
    final workspace = sync.workspaceId;
    final category = workspace == null
        ? null
        : SavedReadPolicy.category(options, workspace);
    if (owner != null && category != null && hasSession()) {
      final sorted = Map.fromEntries(
        options.queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );
      final url = options.uri
          .replace(
            queryParameters: sorted.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          )
          .toString();
      final key = sync.store.key(owner, url);
      options.extra[_context] = _ReadContext(
        owner,
        sync.generation,
        category,
        key,
      );
      sync.begin(category);
      if (sync.store.read(key, owner, _now().toUtc()) != null) {
        options.connectTimeout = const Duration(seconds: 5);
        options.receiveTimeout = const Duration(seconds: 5);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final context = response.requestOptions.extra[_context];
    if (context is _ReadContext && _current(context)) {
      final now = _now().toUtc();
      await sync.store.write(
        context.key,
        SavedRead(owner: context.owner, data: response.data, updatedAt: now),
      );
      if (_current(context)) sync.finish(context.category, updatedAt: now);
    } else if (response.requestOptions.method != 'GET' &&
        RegExp(r'/(attendance|shifts|shift-templates|leave-requests)(/|$)')
            .hasMatch(response.requestOptions.path) &&
        sync.owner != null &&
        (response.statusCode ?? 500) < 300) {
      // A mutation invalidates prior snapshots instead of presenting obsolete data.
      await sync.store.clearOwner(sync.owner!);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final context = error.requestOptions.extra[_context];
    if (context is _ReadContext && _current(context)) {
      if (SavedReadPolicy.connectionFailure(error)) {
        final saved = sync.store.read(
          context.key,
          context.owner,
          _now().toUtc(),
        );
        if (saved != null) {
          sync.finish(
            context.category,
            updatedAt: saved.updatedAt,
            saved: true,
          );
          handler.resolve(
            Response(
              requestOptions: error.requestOptions,
              data: saved.data,
              statusCode: 200,
              extra: {'fromSavedRead': true, 'updatedAt': saved.updatedAt},
            ),
          );
          return;
        }
      } else if (const {401, 403, 404}.contains(error.response?.statusCode)) {
        await sync.store.remove(context.key);
      }
      if (_current(context)) sync.finish(context.category, failed: true);
    }
    handler.next(error);
  }

  bool _current(_ReadContext context) =>
      hasSession() && sync.current(context.owner, context.generation);
}

class _ReadContext {
  const _ReadContext(this.owner, this.generation, this.category, this.key);
  final String owner;
  final int generation;
  final ReadCategory category;
  final String key;
}
