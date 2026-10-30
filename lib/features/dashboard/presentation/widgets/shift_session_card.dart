import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_status_card.dart';

class ShiftSessionCard extends StatefulWidget {
  const ShiftSessionCard({
    required this.state,
    required this.timezone,
    this.breaks,
    this.now,
    super.key,
  });
  final FlexibleAttendanceState state;
  final String timezone;
  final ShiftBreakController? breaks;
  final DateTime Function()? now;
  @override
  State<ShiftSessionCard> createState() => _ShiftSessionCardState();
}

class _ShiftSessionCardState extends State<ShiftSessionCard>
    with WidgetsBindingObserver {
  Timer? _ticker;
  ShiftBreakController? _breaks;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = widget.breaks ?? context.read<ShiftBreakController?>();
    if (_breaks != next) {
      _breaks?.removeListener(_changed);
      _breaks = next;
      _breaks?.addListener(_changed);
    }
    _restore();
  }

  @override
  void didUpdateWidget(covariant ShiftSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _restore();
  }

  void _restore() {
    final active = widget.state.current;
    if (active?.isOpen == true) _breaks?.restore(active!.id);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _changed();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breaks?.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _duration(Duration value) {
    final mins = value.inMinutes.clamp(0, 999999);
    return context.tr('{hours}h {minutes}m', {
      'hours': '${mins ~/ 60}',
      'minutes': '${mins % 60}',
    });
  }

  Future<void> _clockOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr('Clock out now?')),
        content: Text(
          c.tr('Your final worked duration will be calculated by the server.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-home-clock-out'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr('Clock out')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await context.read<FlexibleAttendanceCubit>().clockOut();
    if (!mounted) return;
    if (result == FixedShiftMutationResult.success) await _breaks?.finish();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            result == FixedShiftMutationResult.success
                ? 'Clock-out confirmed.'
                : 'Could not clock out. Check your attendance and retry.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state, active = state.current;
    if (active == null ||
        !active.isOpen ||
        !active.isActionable ||
        state.legacyReviewRequired ||
        state.recoveryBlocked ||
        state.failure != null) {
      return AttendanceStatusCard(
        state: state,
        timezone: widget.timezone,
        onOpenShifts: () => context.go('/employee?tab=shifts'),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final now = widget.now?.call() ?? DateTime.now();
    final end = active.scheduledEndAt;
    final start = active.scheduledStartAt ?? active.clockInAt;
    final elapsed = now.difference(active.clockInAt);
    final remaining = end?.difference(now);
    final length = end?.difference(start).inSeconds ?? 0;
    final progress = length <= 0
        ? 0.0
        : (now.difference(start).inSeconds / length).clamp(0.0, 1.0);
    final onBreak = _breaks?.running == true;
    final disabled =
        state.clockingOut ||
        state.refreshing ||
        state.loading ||
        _breaks?.busy == true;
    final locale = Localizations.localeOf(context).toString();
    return Container(
      key: const Key('shift-session-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.tr(onBreak ? 'ON BREAK' : 'ON SHIFT NOW'),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              if (end != null)
                Text(
                  '${WorkspaceTime.time(start, widget.timezone, locale: locale)} – ${WorkspaceTime.time(end, widget.timezone, locale: locale)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              key: const Key('home-clock-out'),
              tooltip: context.tr('Clock out'),
              onPressed: disabled ? null : _clockOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _duration(
              onBreak
                  ? _breaks!.remaining
                  : remaining != null && !remaining.isNegative
                  ? remaining
                  : elapsed,
            ),
            key: const Key('shift-main-time'),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          Text(
            context.tr(
              onBreak
                  ? 'Break remaining'
                  : remaining == null
                  ? 'Time worked'
                  : remaining.isNegative
                  ? 'Shift ended · time worked'
                  : 'Left in this shift',
            ),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: onBreak
                ? (1 - _breaks!.remaining.inSeconds / 3600).clamp(0.0, 1.0)
                : progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('Worked {time}', {'time': _duration(elapsed)}),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('start-shift-break'),
                onPressed:
                    disabled || _breaks == null || (!onBreak && _breaks!.used)
                    ? null
                    : () async {
                        if (onBreak) {
                          await _breaks!.finish();
                        } else {
                          await _breaks!.start(
                            arabic:
                                Localizations.localeOf(context).languageCode ==
                                'ar',
                          );
                        }
                      },
                icon: Icon(
                  onBreak ? Icons.play_arrow_rounded : Icons.coffee_outlined,
                  size: 18,
                ),
                label: Text(
                  context.tr(
                    onBreak
                        ? 'End break'
                        : _breaks?.used == true
                        ? 'Break used'
                        : 'Start break',
                  ),
                ),
              ),
            ],
          ),
          if (onBreak && !_breaks!.notificationScheduled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr(
                  'Timer is running. Enable notifications to receive a background alert.',
                ),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
          if (_breaks?.error != null)
            Text(
              context.tr(_breaks!.error!),
              style: TextStyle(color: colors.error),
            ),
          if (_breaks?.used == true && !onBreak)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('Your break has ended.'),
                style: TextStyle(color: colors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
