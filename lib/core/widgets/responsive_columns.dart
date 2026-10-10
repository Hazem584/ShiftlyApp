import 'package:flutter/material.dart';

/// Wraps by available content width rather than the browser's overall width.
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    required this.children,
    this.minimumWidth = 420,
    this.spacing = 20,
    super.key,
  });
  final List<Widget> children;
  final double minimumWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / (minimumWidth + spacing))
          .floor()
          .clamp(1, children.length);
      final width = (constraints.maxWidth - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
