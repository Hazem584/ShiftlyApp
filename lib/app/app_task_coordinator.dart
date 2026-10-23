import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/device_task_reminders.dart';

class AppTaskCoordinator {
  AppTaskCoordinator(this.cubit, this.router, this.isMounted) {
    final reminders = cubit.reminders;
    if (reminders is DeviceTaskReminders) {
      _taps = reminders.opened.stream.listen((tap) {
        _pending = tap;
        unawaited(openPending());
      });
    }
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          cubit.scope != null) {
        unawaited(cubit.syncReminders());
      }
    });
  }
  final TasksCubit cubit;
  final GoRouter router;
  final bool Function() isMounted;
  Timer? _refresh;
  StreamSubscription<Map<String, Object?>>? _taps;
  Map<String, Object?>? _pending;
  Future<void> bindSession(FeatureSessionScope? scope) async {
    await cubit.bindSession(scope);
    await openPending();
  }

  Future<void> openPending() async {
    final reminders = cubit.reminders;
    if (reminders is DeviceTaskReminders && reminders.initialTap != null) {
      _pending ??= reminders.initialTap;
      reminders.initialTap = null;
    }
    final tap = _pending, scope = cubit.scope;
    if (tap == null || scope == null) return;
    _pending = null;
    final owner = tap['ownerId'], id = tap['taskId'];
    if (owner is! String || id is! String) return;
    final task = await cubit.resolveTap(owner, id);
    if (task == null || !isMounted() || cubit.scope != scope) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isMounted() && cubit.scope == scope) {
        router.push('/tasks?taskId=${task.id}');
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void dispose() {
    _refresh?.cancel();
    unawaited(_taps?.cancel());
    unawaited(cubit.close());
  }
}
