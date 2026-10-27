import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 48, super.key});
  static const asset = 'assets/images/shiftly-mark.png';
  final double size;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF0B1014),
      borderRadius: BorderRadius.circular(size * .2),
    ),
    child: Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Shiftly logo',
    ),
  );
}
