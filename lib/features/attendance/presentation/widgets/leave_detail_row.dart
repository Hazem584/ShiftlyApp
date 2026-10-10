import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';

class LeaveDetailRow extends StatelessWidget {
  const LeaveDetailRow({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppPalette.of(context).textSecondary),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppPalette.of(context).textSecondary,
          ),
        ),
      ),
    ],
  );
}
