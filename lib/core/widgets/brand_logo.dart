import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 48, super.key});
  static const asset = 'assets/images/Logo.png';
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'Shiftly logo',
  );
}
