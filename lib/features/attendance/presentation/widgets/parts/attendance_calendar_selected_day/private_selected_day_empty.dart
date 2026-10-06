part of '../../attendance_calendar_selected_day.dart';

class _SelectedDayEmpty extends StatelessWidget {
  const _SelectedDayEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
