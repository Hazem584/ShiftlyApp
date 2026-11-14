import 'package:flutter/material.dart';

class ManagerDesign extends ThemeExtension<ManagerDesign> {
  const ManagerDesign();
  static bool applies(BuildContext context) =>
      Theme.of(context).extension<ManagerDesign>() != null;
  @override
  ManagerDesign copyWith() => this;
  @override
  ManagerDesign lerp(covariant ManagerDesign? other, double t) => this;
}
