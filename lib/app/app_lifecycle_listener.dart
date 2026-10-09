import 'package:flutter/widgets.dart';

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

class _ShiftlyAppLifecycleListenerState
    extends State<ShiftlyAppLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onResumed();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
