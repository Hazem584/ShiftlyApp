import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class WorkspaceContentFrame extends StatelessWidget {
  const WorkspaceContentFrame({
    required this.child,
    this.framed = false,
    super.key,
  });
  final Widget child;
  final bool framed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(framed ? 24 : 0),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: SizedBox.expand(
          child: framed
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    ),
  );
}
