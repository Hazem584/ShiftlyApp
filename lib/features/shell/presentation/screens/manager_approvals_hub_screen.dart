import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/team_work/presentation/team_work_screen.dart';

class ManagerApprovalsHubScreen extends StatefulWidget {
  const ManagerApprovalsHubScreen({
    super.key,
    required this.initialSection,
    required this.timezone,
  });
  final String initialSection;
  final String timezone;

  @override
  State<ManagerApprovalsHubScreen> createState() =>
      _ManagerApprovalsHubScreenState();
}

class _ManagerApprovalsHubScreenState extends State<ManagerApprovalsHubScreen> {
  late String _tab = widget.initialSection;

  static const _tabs = [
    ('Action inbox', 'tasks'),
    ('Team records', 'attendance'),
    ('Team requests', 'leave'),
    ('Review requests', 'corrections'),
    ('Monthly calendar', 'calendar'),
  ];

  @override
  void didUpdateWidget(covariant ManagerApprovalsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _tab = widget.initialSection;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            for (final item in _tabs)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  key: Key('approvals-tab-${item.$2}'),
                  label: Text(context.tr(item.$1)),
                  selected: _tab == item.$2,
                  onSelected: (_) => setState(() => _tab = item.$2),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: switch (_tab) {
          'attendance' => AttendanceScreen(
            timezone: widget.timezone,
            initialTab: 0,
          ),
          'leave' => AttendanceScreen(timezone: widget.timezone, initialTab: 1),
          'corrections' => const TeamWorkScreen(initialTab: 'corrections'),
          'calendar' => AttendanceScreen(
            timezone: widget.timezone,
            initialTab: 2,
          ),
          _ => const TeamWorkScreen(initialTab: 'tasks'),
        },
      ),
    ],
  );
}
