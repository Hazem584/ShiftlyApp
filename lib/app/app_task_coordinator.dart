import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/device_task_reminders.dart';
import 'package:shiftly/features/tasks/data/native_task_home_widget.dart';

class AppTaskCoordinator with WidgetsBindingObserver {
  AppTaskCoordinator(this.cubit, this.router, this.isMounted) {
    WidgetsBinding.instance.addObserver(this);
    if (NativeTaskHomeWidget.supported) {
      NativeTaskHomeWidget.channel.setMethodCallHandler((call) async {
        if (call.method != 'opened' || call.arguments is! Map) return;
        _pending = Map<String, Object?>.from(call.arguments as Map);
        unawaited(openPending());
      });
      unawaited(_initialWidgetTap());
    }
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
        unawaited(cubit.widgetSync?.refresh());
      }
    });
  }
  Future<void> _initialWidgetTap() async {
    try {
      final tap = await NativeTaskHomeWidget.channel
          .invokeMapMethod<String, Object?>('initialTap');
      if (tap != null) {
        _pending = tap;
        await openPending();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(cubit.refresh());
      unawaited(openPending());
    }
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
    if (id.isEmpty) {
      if ((owner.isEmpty || owner == scope.userId) && isMounted()) {
        router.push('/tasks');
      }
      return;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    if (NativeTaskHomeWidget.supported) {
      NativeTaskHomeWidget.channel.setMethodCallHandler(null);
    }
    _refresh?.cancel();
    unawaited(_taps?.cancel());
    unawaited(cubit.close());
  }
}
