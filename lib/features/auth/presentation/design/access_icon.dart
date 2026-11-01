import 'package:flutter/material.dart';

import 'access_icon_painter.dart';

class AccessIcon extends StatelessWidget {
  const AccessIcon(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: const Size(24, 24),
      painter: AccessIconPainter(
        name,
        Theme.of(context).colorScheme.onSurfaceVariant,
        name == 'back' && Directionality.of(context) == TextDirection.rtl,
      ),
    ),
  );
}
