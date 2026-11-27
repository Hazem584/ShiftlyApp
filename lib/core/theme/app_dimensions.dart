import 'package:flutter/material.dart';

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

class AppRadii {
  static const double s = 12;
  static const double m = 12;
  static const double l = 14;
  static const double xl = 18;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x07133B28), blurRadius: 20, offset: Offset(0, 6)),
  ];
}
