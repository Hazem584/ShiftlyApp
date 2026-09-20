import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: const [
      _Skeleton(height: 42, width: 180),
      SizedBox(height: 16),
      _Skeleton(height: 160),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _Skeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: _Skeleton(height: 120)),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _Skeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: _Skeleton(height: 120)),
        ],
      ),
      SizedBox(height: 20),
      Center(
        child: Text(
          'Preparing your dashboard…',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    ),
  );
}
