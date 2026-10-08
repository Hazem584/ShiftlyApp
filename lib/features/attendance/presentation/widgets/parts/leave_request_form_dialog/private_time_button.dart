part of '../../leave_request_form_dialog.dart';

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final TimeOfDay value;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Text(
      '$label: ${ClockTime.format(value.hour, value.minute, locale: Localizations.localeOf(context).toString())}',
    ),
  );
}
