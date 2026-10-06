import 'package:flutter/widgets.dart';

part 'parts/app_lifecycle_listener/private_shiftly_app_lifecycle_listener_state.dart';

class ShiftlyAppLifecycleListener extends StatefulWidget {
  const ShiftlyAppLifecycleListener({
    required this.onResumed,
    required this.child,
    super.key,
  });

  final VoidCallback onResumed;
  final Widget child;

  @override
  State<ShiftlyAppLifecycleListener> createState() =>
      _ShiftlyAppLifecycleListenerState();
}
