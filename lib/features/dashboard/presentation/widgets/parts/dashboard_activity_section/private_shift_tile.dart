part of '../../dashboard_activity_section.dart';

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({required this.shift, required this.timezone});
  final DashboardShiftPreview shift;
  final String timezone;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.field,
      foregroundColor: AppColors.ink,
      child: Text(shift.employee.fullName.characters.first.toUpperCase()),
    ),
    title: Text(
      shift.employee.fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${WorkspaceTime.time(shift.startsAt, timezone, locale: Localizations.localeOf(context).toString())} – '
      '${WorkspaceTime.time(shift.endsAt, timezone, locale: Localizations.localeOf(context).toString())}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      _attendanceLabel(shift.attendance),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
