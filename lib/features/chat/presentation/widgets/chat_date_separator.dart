import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatDateSeparator extends StatelessWidget {
  const ChatDateSeparator({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final text = DateUtils.isSameDay(local, now)
        ? context.tr('Today')
        : DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))
        ? context.tr('Yesterday')
        : MaterialLocalizations.of(context).formatMediumDate(local);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
