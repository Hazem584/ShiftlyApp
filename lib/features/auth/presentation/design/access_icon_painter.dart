import 'package:flutter/material.dart';

/// Vector paths exported from Penpot; no replacement glyphs or SVG dependency.
class AccessIconPainter extends CustomPainter {
  const AccessIconPainter(this.name, this.color, this.mirror);
  final String name;
  final Color color;
  final bool mirror;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    if (mirror) {
      canvas.translate(24, 0);
      canvas.scale(-1, 1);
    }
    final path = Path();
    switch (name) {
      case 'back':
        path.moveTo(15, 5);
        path.lineTo(8, 12);
        path.lineTo(15, 19);
        break;
      case 'file':
        path.moveTo(5, 2);
        path.lineTo(14, 2);
        path.lineTo(19, 7);
        path.lineTo(19, 22);
        path.lineTo(5, 22);
        path.lineTo(5, 2);
        path.moveTo(14, 2);
        path.lineTo(14, 8);
        path.lineTo(19, 8);
        path.moveTo(8, 12);
        path.lineTo(16, 12);
        path.moveTo(8, 16);
        path.lineTo(14, 16);
        break;
      case 'user':
        path.moveTo(4, 21);
        path.lineTo(4, 19);
        path.cubicTo(4, 14.58167, 7.58173, 11, 12, 11);
        path.cubicTo(16.41827, 11, 20, 14.58167, 20, 19);
        path.lineTo(20, 21);
        path.moveTo(12, 3);
        path.cubicTo(9.79083, 3, 8, 4.79089, 8, 7);
        path.cubicTo(8, 9.20911, 9.79083, 11, 12, 11);
        path.cubicTo(14.20917, 11, 16, 9.20911, 16, 7);
        path.cubicTo(16, 4.79089, 14.20917, 3, 12, 3);
        break;
      case 'work':
        path.moveTo(4, 6);
        path.lineTo(20, 6);
        path.lineTo(20, 21);
        path.lineTo(4, 21);
        path.lineTo(4, 6);
        path.moveTo(8, 6);
        path.lineTo(8, 3);
        path.lineTo(16, 3);
        path.lineTo(16, 6);
        path.moveTo(8, 11);
        path.lineTo(16, 11);
        path.moveTo(8, 16);
        path.lineTo(13, 16);
        break;
      case 'plus':
        path.moveTo(12, 5);
        path.lineTo(12, 19);
        path.moveTo(5, 12);
        path.lineTo(19, 12);
        break;
      case 'clock':
        path.moveTo(12, 3);
        path.cubicTo(7.02944, 3, 3, 7.02954, 3, 12);
        path.cubicTo(3, 16.97046, 7.02944, 21, 12, 21);
        path.cubicTo(16.97056, 21, 21, 16.97046, 21, 12);
        path.cubicTo(21, 7.02954, 16.97056, 3, 12, 3);
        path.moveTo(12, 7);
        path.lineTo(12, 12);
        path.lineTo(16, 14);
        break;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(AccessIconPainter oldDelegate) =>
      name != oldDelegate.name ||
      color != oldDelegate.color ||
      mirror != oldDelegate.mirror;
}
