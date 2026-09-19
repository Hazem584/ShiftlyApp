import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedTab = 0;

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

  Future<void> _requestLeave() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LeaveRequestSheet(),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
    }
  }

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
          FilledButton.icon(
            onPressed: _requestLeave,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Request Leave'),
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
              ButtonSegment(value: 0, label: Text('Attendance')),
              ButtonSegment(value: 1, label: Text('Leave Requests')),
              ButtonSegment(value: 2, label: Text('Calendar')),
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
            const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No open leave requests',
              message: 'New leave requests will appear here for review.',
            )
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
