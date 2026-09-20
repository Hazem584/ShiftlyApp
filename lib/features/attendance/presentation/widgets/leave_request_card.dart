import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/attendance_request.dart';
import 'package:shiftly/core/models/leave_request.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    required this.request,
    required this.updating,
    super.key,
  });
  final LeaveRequest request;
  final bool updating;

  Future<void> _decide(BuildContext context, RequestStatus status) async {
    if (status == RequestStatus.rejected) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reject request?'),
          content: Text(
            'Reject ${request.employeeName}’s request? This updates the current session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-reject'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final success = await context.read<LeaveRequestsCubit>().decide(
      request.id,
      status,
    );
    if (!context.mounted) return;
    if (success) {
      ToastService.success(
        context,
        message:
            'Request ${status == RequestStatus.approved ? 'approved' : 'rejected'}',
      );
    } else {
      ToastService.error(context, message: 'Could not update request');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = request.status == RequestStatus.pending;
    return SurfaceCard(
      key: Key('request-${request.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.selected,
                foregroundColor: AppColors.ink,
                child: Text(
                  request.employeeInitials,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _typeLabel(request.type),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _RequestStatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 13),
          _RequestDetail(
            icon: Icons.calendar_today_outlined,
            text: _dateRange(request),
          ),
          const SizedBox(height: 7),
          _RequestDetail(icon: Icons.notes_rounded, text: request.reason),
          const SizedBox(height: 7),
          _RequestDetail(
            icon: Icons.schedule_rounded,
            text: 'Submitted ${_dateTime(request.submittedAt)}',
          ),
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key('reject-${request.id}'),
                    onPressed: updating
                        ? null
                        : () => _decide(context, RequestStatus.rejected),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    key: Key('approve-${request.id}'),
                    onPressed: updating
                        ? null
                        : () => _decide(context, RequestStatus.approved),
                    icon: updating
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Reviewed ${_dateTime(request.reviewedAt!)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});
  final RequestStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      RequestStatus.pending => (
        'Pending',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      RequestStatus.approved => (
        'Approved',
        AppColors.success,
        AppColors.successSoft,
      ),
      RequestStatus.rejected => (
        'Rejected',
        AppColors.error,
        const Color(0xFFFFE5E3),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _typeLabel(LeaveRequestType type) => switch (type) {
  LeaveRequestType.leave => 'Leave request',
  LeaveRequestType.earlyDeparture => 'Early departure',
};
String _dateRange(LeaveRequest request) {
  final start =
      '${request.startDate.day}/${request.startDate.month}/${request.startDate.year}';
  final end =
      '${request.endDate.day}/${request.endDate.month}/${request.endDate.year}';
  return request.startDate == request.endDate ? start : '$start – $end';
}

String _dateTime(DateTime value) =>
    '${value.day}/${value.month}/${value.year} at ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
