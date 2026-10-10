import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key, required this.height, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppPalette.of(context).field,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    ),
  );
}
