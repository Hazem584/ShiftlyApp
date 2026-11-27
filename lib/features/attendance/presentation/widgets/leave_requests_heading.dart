import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';

class LeaveRequestsHeading extends StatelessWidget {
  const LeaveRequestsHeading({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          context.tr('Employee requests'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      Text(
        context.tr('{value1} loaded', {'value1': count.toString()}),
        style: TextStyle(
          color: AppPalette.of(context).textSecondary,
          fontSize: 12,
        ),
      ),
    ],
  );
}
