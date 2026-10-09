import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class EmployeeDetail extends StatelessWidget {
  const EmployeeDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18),
    ),
    title: Text(
      title,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
    ),
    subtitle: Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
