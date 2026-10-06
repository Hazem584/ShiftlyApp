part of '../../shiftly_chat_message_list.dart';

class _ChatDateSeparator extends StatelessWidget {
  const _ChatDateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final text = DateUtils.isSameDay(local, now)
        ? 'Today'
        : DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))
        ? 'Yesterday'
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
