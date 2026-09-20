import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/attendance_request.dart';
import 'package:shiftly/core/models/leave_request.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({this.initialTab = 0, super.key});
  final int initialTab;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  static const _records = [
    _AttendanceItem(
      day: '15',
      weekday: 'Monday',
      checkIn: '09:00',
      checkOut: '17:30',
      hours: '8.5h',
      location: 'Office',
    ),
    _AttendanceItem(
      day: '14',
      weekday: 'Sunday',
      checkIn: '09:15',
      checkOut: '17:45',
      hours: '8.5h',
      location: 'Office',
    ),
    _AttendanceItem(
      day: '13',
      weekday: 'Saturday',
      checkIn: '09:00',
      checkOut: '17:00',
      hours: '8h',
      location: 'Remote',
    ),
    _AttendanceItem(
      day: '12',
      weekday: 'Friday',
      checkIn: '—',
      checkOut: '—',
      hours: '0h',
      location: '—',
      status: 'Sick Leave',
    ),
    _AttendanceItem(
      day: '11',
      weekday: 'Thursday',
      checkIn: '09:30',
      checkOut: '18:00',
      hours: '8.5h',
      location: 'Office',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        key: const Key('attendance-content'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          const ScreenHeader(
            title: 'Attendance & Leave',
            subtitle: 'Track attendance and manage leave requests',
          ),
          const SizedBox(height: AppSpacing.m),
          BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
            builder: (context, state) {
              final pending = state is LeaveRequestsLoaded
                  ? state.pendingCount
                  : 0;
              return SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.approval_outlined,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Manager review queue',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '$pending pending',
                          key: const Key('pending-request-count'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _AttendanceMetric(
                  label: 'Attendance Rate',
                  value: '94.2%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                SizedBox(width: 10),
                _AttendanceMetric(
                  label: 'Hours Worked',
                  value: '168h',
                  icon: Icons.schedule_rounded,
                  color: AppColors.ink,
                ),
                SizedBox(width: 10),
                _AttendanceMetric(
                  label: 'Avg Hours/Day',
                  value: '8.4h',
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.orange,
                ),
                SizedBox(width: 10),
                _AttendanceMetric(
                  label: 'Leave Requests',
                  value: '1',
                  icon: Icons.error_outline_rounded,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Attendance', key: Key('attendance-tab-records')),
              ),
              ButtonSegment(
                value: 1,
                label: Text(
                  'Leave Requests',
                  key: Key('attendance-tab-requests'),
                ),
              ),
              ButtonSegment(
                value: 2,
                label: Text('Calendar', key: Key('attendance-tab-calendar')),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (value) =>
                setState(() => _selectedTab = value.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.surface
                    : AppColors.field,
              ),
              foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
              side: const WidgetStatePropertyAll(
                BorderSide(color: AppColors.borderColor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (_selectedTab == 0) ...[
            Text(
              'Recent Attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.s),
            for (final record in _records) ...[
              _AttendanceRow(record: record),
              const SizedBox(height: 10),
            ],
          ] else if (_selectedTab == 1)
            const _LeaveRequestsPanel()
          else
            const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Calendar view',
              message: 'The team attendance calendar will be connected in a future sprint.',
            ),
        ],
      ),
    ),
  );
}

class _LeaveRequestsPanel extends StatelessWidget {
  const _LeaveRequestsPanel();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
        builder: (context, state) => switch (state) {
          LeaveRequestsLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          LeaveRequestsError(:final message) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load requests',
            message: message,
            action: FilledButton(
              onPressed: context.read<LeaveRequestsCubit>().load,
              child: const Text('Retry'),
            ),
          ),
          LeaveRequestsLoaded(:final requests, :final updatingId) =>
            requests.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'All caught up',
                    message:
                        'New employee requests will appear here for review.',
                  )
                : Column(
                    key: const Key('leave-request-list'),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Employee requests',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            '${requests.length} total',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      for (final request in requests) ...[
                        _RequestCard(
                          request: request,
                          updating: updatingId == request.id,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
        },
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.updating});
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Request ${status == RequestStatus.approved ? 'approved' : 'rejected'}'
              : 'Could not update request',
        ),
      ),
    );
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

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    child: SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          Icon(icon, color: color, size: 27),
        ],
      ),
    ),
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});
  final _AttendanceItem record;
  @override
  Widget build(BuildContext context) {
    final isLeave = record.status != 'Present';
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  record.day,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Jan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.weekday,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'In: ${record.checkIn}   Out: ${record.checkOut}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        record.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.hours,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isLeave ? AppColors.purpleSoft : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: isLeave
                          ? const Color(0xFF7A27A8)
                          : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestSheet extends StatefulWidget {
  const _LeaveRequestSheet();
  @override
  State<_LeaveRequestSheet> createState() => _LeaveRequestSheetState();
}

class _LeaveRequestSheetState extends State<_LeaveRequestSheet> {
  final _key = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _type;
  DateTime? _start;
  DateTime? _end;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final date = await showDatePicker(
      context: context,
      initialDate: start
          ? (_start ?? DateTime.now())
          : (_end ?? _start ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) setState(() => start ? _start = date : _end = date);
  }

  void _submit() {
    if (!(_key.currentState?.validate() ?? false)) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a start and end date')),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request Leave',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Leave type',
                hintText: 'Select leave type',
              ),
              items:
                  const [
                        'Vacation',
                        'Sick Leave',
                        'Personal',
                        'Maternity',
                        'Bereavement',
                      ]
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _type = value),
              validator: (value) =>
                  value == null ? 'Select a leave type' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start date',
                    date: _start,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'End date',
                    date: _end,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Please provide a reason…',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Enter a short reason'
                  : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadii.m),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 17),
      ),
      child: Text(
        date == null
            ? 'mm/dd/yyyy'
            : '${date!.month}/${date!.day}/${date!.year}',
        style: TextStyle(
          color: date == null ? AppColors.textSecondary : AppColors.ink,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _AttendanceItem {
  const _AttendanceItem({
    required this.day,
    required this.weekday,
    required this.checkIn,
    required this.checkOut,
    required this.hours,
    required this.location,
    this.status = 'Present',
  });
  final String day;
  final String weekday;
  final String checkIn;
  final String checkOut;
  final String hours;
  final String location;
  final String status;
}
