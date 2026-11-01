import 'package:flutter/material.dart';

class AccessAction extends StatelessWidget {
  const AccessAction({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.actionKey,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Key? actionKey;
  @override
  Widget build(BuildContext context) => FilledButton(
    key: actionKey,
    onPressed: busy ? null : onPressed,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: busy ? 0 : 1,
          child: Text(label, textAlign: TextAlign.center),
        ),
        if (busy)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
      ],
    ),
  );
}
