import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';

class AttendanceRejectionDialog extends StatefulWidget {
  const AttendanceRejectionDialog({
    required this.cubit,
    required this.attendanceId,
    super.key,
  });

  final ManagerAttendanceCubit cubit;
  final String attendanceId;

  @override
  State<AttendanceRejectionDialog> createState() =>
      _AttendanceRejectionDialogState();
}

class _AttendanceRejectionDialogState extends State<AttendanceRejectionDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || ModalRoute.of(context)?.isCurrent != true) return;
    final reason = _controller.text.trim();
    if (reason.isEmpty || reason.length > 1000) {
      setState(() {
        _error = reason.isEmpty
            ? 'A rejection reason is required.'
            : 'Rejection reason is too long.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.cubit.review(
      widget.attendanceId,
      AttendanceReviewDecision.rejected,
      rejectionReason: reason,
    );
    if (!mounted) return;
    // A dismissed dialog can still be mounted during its reverse animation.
    // Its response must never pop the route beneath it.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (result == AttendanceMutationResult.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error =
          widget.cubit.state.failure?.message ??
          'Unable to review attendance. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reject attendance?'),
    content: TextField(
      key: const Key('attendance-rejection-reason'),
      controller: _controller,
      enabled: !_submitting,
      maxLength: 1000,
      maxLines: 3,
      decoration: InputDecoration(labelText: 'Reason', errorText: _error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        key: const Key('confirm-reject-attendance'),
        onPressed: _submitting ? null : _submit,
        child: const Text('Reject'),
      ),
    ],
  );
}
