import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_attendance_actions.dart';
import 'employee_tile.dart';

class EmployeeBreakPanel extends StatefulWidget {
  const EmployeeBreakPanel({
    required this.attendance,
    required this.timezone,
    super.key,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  @override
  State<EmployeeBreakPanel> createState() => _EmployeeBreakPanelState();
}

class _EmployeeBreakPanelState extends State<EmployeeBreakPanel> {
  ShiftBreakController? _breaks;
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<ShiftBreakController?>();
    if (next != _breaks) {
      _breaks?.removeListener(_changed);
      _breaks = next;
      _breaks?.addListener(_changed);
    }
    _restore();
  }

  @override
  void didUpdateWidget(covariant EmployeeBreakPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _restore();
  }

  void _restore() {
    _breaks?.restore(
      widget.attendance.id,
      policy: widget.attendance.breakState,
      arabic: Localizations.localeOf(context).languageCode == 'ar',
    );
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breaks?.removeListener(_changed);
    super.dispose();
  }

  Future<void> _toggle() async {
    final b = _breaks;
    if (b == null || b.busy) return;
    if (b.running) {
      await b.end();
      return;
    }
    if (!b.canStart) return;
    final ok = await confirmEmployeeAction(
      context,
      title: 'Start a break?',
      message: context.tr('Available break: {duration}', {
        'duration': workDuration(
          b.availableSeconds ~/ 60,
          arabic: Localizations.localeOf(context).languageCode == 'ar',
        ),
      }),
      action: 'Start break',
    );
    if (ok && mounted && b.canStart) {
      await b.start(
        arabic: Localizations.localeOf(context).languageCode == 'ar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _breaks;
    if (b == null) return const SizedBox.shrink();
    final running = b.running;
    final remaining = b.remaining;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeTile(
          icon: Icons.coffee_outlined,
          title: context.tr(running ? 'Break timer' : 'A moment to recharge'),
          subtitle: running
              ? '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} · ${context.tr('remaining')}'
              : context.tr('Available break: {duration}', {
                  'duration': workDuration(
                    b.availableSeconds ~/ 60,
                    arabic:
                        Localizations.localeOf(context).languageCode == 'ar',
                  ),
                }),
          onTap: !b.busy && (running || b.canStart) ? _toggle : null,
        ),
        const SizedBox(height: 12),
        if (running || b.canStart)
          OutlinedButton(
            key: const Key('employee-break-action'),
            onPressed: b.busy ? null : _toggle,
            child: Text(context.tr(running ? 'End break' : 'Start break')),
          ),
        if (b.reminderAt != null && !running)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('Break at {time}', {
                'time': WorkspaceTime.time(
                  b.reminderAt!,
                  widget.timezone,
                  locale: Localizations.localeOf(context).toString(),
                ),
              }),
            ),
          ),
        if ((widget.attendance.breakState?.lateDeductionMinutes ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('Break reduced by {time} for late arrival.', {
                'time': workDuration(
                  widget.attendance.breakState!.lateDeductionMinutes,
                  arabic: Localizations.localeOf(context).languageCode == 'ar',
                ),
              }),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            context.tr(
              'Breaks are recorded against your allowance. Unused break and overtime follow your workspace attendance rules.',
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (running && !b.notificationScheduled)
          Text(
            context.tr(
              'Timer is running. Enable notifications to receive a background alert.',
            ),
          ),
        if (b.error != null)
          Text(
            context.tr(b.error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
