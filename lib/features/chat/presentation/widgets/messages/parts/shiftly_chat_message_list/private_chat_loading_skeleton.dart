part of '../../shiftly_chat_message_list.dart';

class _ChatLoadingSkeleton extends StatelessWidget {
  const _ChatLoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, index) => Align(
      alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: index.isEven ? 210 : 160,
        height: 52,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}
