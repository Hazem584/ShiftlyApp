import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class EmployeeAttendanceHeroBadge extends StatelessWidget {
  const EmployeeAttendanceHeroBadge({
    required this.onBreak,
    required this.isOpen,
    required this.dark,
    super.key,
  });

  final bool onBreak;
  final bool isOpen;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFF88E3BF) : const Color(0xFF116B57);
    final label = context
        .tr(
          onBreak
              ? '● On break'
              : isOpen
              ? '● On shift'
              : 'Shift complete',
        )
        .replaceAll('●', '')
        .trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF163D35) : const Color(0xFFDCF5EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
