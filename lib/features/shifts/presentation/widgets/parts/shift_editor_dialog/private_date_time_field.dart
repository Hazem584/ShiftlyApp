part of '../../shift_editor_dialog.dart';

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.timezone,
    required this.onTap,
    super.key,
  });
  final String label;
  final DateTime value;
  final String timezone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
    ),
    tileColor: Theme.of(context).inputDecorationTheme.fillColor,
    leading: const Icon(Icons.event_outlined),
    title: Text(label),
    subtitle: Text(
      '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${ClockTime.wallTime(value, locale: Localizations.localeOf(context).toString())} · $timezone',
    ),
  );

  String _two(int value) => value.toString().padLeft(2, '0');
}
