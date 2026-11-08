import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';

import 'session_coordinator.dart';

class WorkspaceAccessMonitor {
  WorkspaceAccessMonitor(this.api, this.session, this.cache, {this.onRemoval}) {
    interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['workspaceAccessUser'] = session.state.currentUser?.id;
        handler.next(options);
      },
      onError: (error, handler) {
        final current = session.state;
        final id = current.activeMembership?.workspace.id;
        final user = current.currentUser?.id;
        final parsed = ApiErrorParser.parse(error);
        if (id != null &&
            user != null &&
            error.requestOptions.extra['workspaceAccessUser'] == user &&
            (error.requestOptions.path == '/workspaces/$id' ||
                error.requestOptions.path.startsWith('/workspaces/$id/')) &&
            {
              'WORKSPACE_NOT_FOUND',
              'WORKSPACE_ACCESS_DENIED',
            }.contains(parsed.code)) {
          unawaited(_remove(id, user).catchError((Object _) {}));
        }
        handler.next(error);
      },
    );
    api.interceptors.add(interceptor);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }
  final Future<void> Function(String, String)? onRemoval;
  final Dio api;
  final SessionCoordinator session;
  final SavedReadStore cache;
  late final Interceptor interceptor;
  Timer? timer;
  bool busy = false, disposed = false;
  Future<void> _remove(String id, String user) async {
    if (disposed ||
        session.state.currentUser?.id != user ||
        session.state.activeMembership?.workspace.id != id) {
      return;
    }
    if (onRemoval case final remove?) {
      await remove(id, user);
    } else {
      await session.workspaceLeft(id, user);
      await cache.clearWorkspace(user, id);
    }
  }

  Future<void> check() async {
    final current = session.state;
    final id = current.activeMembership?.workspace.id;
    if (disposed || busy || !current.isAuthenticated || id == null) return;
    busy = true;
    try {
      await api.get<Object?>(
        '/workspaces/$id',
        options: Options(extra: {'requireFresh': true}),
      );
    } catch (_) {
    } finally {
      busy = false;
    }
  }

  void dispose() {
    disposed = true;
    timer?.cancel();
    api.interceptors.remove(interceptor);
  }
}
