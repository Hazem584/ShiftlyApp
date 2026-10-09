import 'package:flutter/material.dart';

class LeaveRequestDateButton extends StatelessWidget {
  const LeaveRequestDateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final DateTime value;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined),
    label: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$label: ${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      ),
    ),
  );
}
