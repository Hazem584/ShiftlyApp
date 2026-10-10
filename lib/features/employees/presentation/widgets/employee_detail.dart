import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';

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
        color: AppPalette.of(context).field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: AppPalette.of(context).textSecondary,
        fontSize: 11,
      ),
    ),
    subtitle: Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppPalette.of(context).ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
