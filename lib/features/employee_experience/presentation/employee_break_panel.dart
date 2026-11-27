import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/flexible_attendance.dart';

import 'employee_break_panel_content.dart';

class EmployeeBreakPanel extends StatefulWidget {
  const EmployeeBreakPanel({
    required this.attendance,
    required this.timezone,
    this.enabled = true,
    super.key,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  final bool enabled;
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
    if (!widget.enabled || b == null || b.busy) return;
    if (b.running) return b.end();
    if (!b.canStart) return;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final ok = await confirmAction(
      context,
      title: 'Start a break?',
      message: context.tr('Available break: {duration}', {
        'duration': workDuration(b.availableSeconds ~/ 60, arabic: arabic),
      }),
      action: 'Start break',
    );
    if (ok && mounted && widget.enabled && b.canStart) {
      await b.start(arabic: arabic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _breaks;
    if (b == null) return const SizedBox.shrink();
    return EmployeeBreakPanelContent(
      breaks: b,
      attendance: widget.attendance,
      timezone: widget.timezone,
      enabled: widget.enabled,
      onToggle: _toggle,
    );
  }
}
