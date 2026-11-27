import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/hub_section_frame.dart';
import 'package:shiftly/features/shell/presentation/screens/work_hub_section_resolver.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({this.section = 'hub', super.key});
  final String section;
  static const destinations = [
    (
      'Approvals & attendance',
      'Action inbox, attendance records, leave, corrections & calendar',
      'tasks',
    ),
    (
      'Shifts & locations',
      'Shift templates, workplace GPS geofence & selfie rules',
      'shifts',
    ),
    (
      'Tasks & announcements',
      'Personal tasks, team assigned tasks & announcements',
      'personal',
    ),
    (
      'Reports & payroll',
      'Attendance analytics, payroll calculations & Excel/PDF export',
      'reports',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final member = context.read<SessionCoordinator?>()?.state.activeMembership;
    final selected = resolveWorkHubSection(section, member);
    if (selected != null) {
      return HubSectionFrame(
        title: 'Work hub',
        fallback: '/work',
        child: selected,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Work hub'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            member?.workspace.name ?? context.tr('Current workspace'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          for (final item in destinations) ...[
            Card(
              child: ListTile(
                key: Key('work-destination-${item.$3}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                title: Text(context.tr(item.$1)),
                subtitle: Text(context.tr(item.$2)),
                onTap: () => context.push('/work?tab=${item.$3}'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
