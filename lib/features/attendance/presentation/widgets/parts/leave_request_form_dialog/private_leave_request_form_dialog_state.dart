part of '../../leave_request_form_dialog.dart';

class _LeaveRequestFormDialogState extends State<LeaveRequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  LeaveRequestType _type = LeaveRequestType.annualLeave;
  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    final now = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    _startDate = DateTime(now.year, now.month, now.day + 1);
    _endDate = _startDate;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Request leave'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LeaveRequestType>(
                key: const Key('leave-type'),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Leave type'),
                items: LeaveRequestType.values
                    .where((type) => type != LeaveRequestType.unknown)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(leaveTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _type = value ?? _type;
                  if (_type == LeaveRequestType.earlyLeave) {
                    _endDate = _startDate;
                  }
                }),
              ),
              const SizedBox(height: 12),
              _DateButton(
                label: 'Start date',
                value: _startDate,
                onPressed: () => _pickDate(start: true),
              ),
              const SizedBox(height: 8),
              _DateButton(
                label: 'End date',
                value: _endDate,
                onPressed: _type == LeaveRequestType.earlyLeave
                    ? null
                    : () => _pickDate(start: false),
              ),
              if (_type == LeaveRequestType.earlyLeave) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Start time',
                        value: _startTime,
                        onPressed: () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TimeButton(
                        label: 'End time',
                        value: _endTime,
                        onPressed: () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('leave-reason'),
                controller: _reason,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) => value?.trim().isEmpty != false
                    ? 'A reason is required'
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
        buildWhen: (previous, current) => previous.creating != current.creating,
        builder: (context, state) => FilledButton(
          key: const Key('submit-leave-request'),
          onPressed: state.creating ? null : _submit,
          child: state.creating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ),
    ],
  );

  Future<void> _pickDate({required bool start}) async {
    final workspaceNow = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    final firstDate = DateTime(
      workspaceNow.year,
      workspaceNow.month,
      workspaceNow.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(picked) || _type == LeaveRequestType.earlyLeave) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => start ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final early = _type == LeaveRequestType.earlyLeave;
    final startsAt = WorkspaceTime.wallTimeToUtc(
      date: _startDate,
      hour: early ? _startTime.hour : 0,
      minute: early ? _startTime.minute : 0,
      timezoneName: widget.timezone,
    );
    final endsAt = WorkspaceTime.wallTimeToUtc(
      date: early ? _startDate : _endDate,
      hour: early ? _endTime.hour : 23,
      minute: early ? _endTime.minute : 59,
      timezoneName: widget.timezone,
    );
    final cubit = context.read<EmployeeLeaveRequestsCubit>();
    final result = await cubit.create(
      CreateLeaveRequestInput(
        type: _type,
        startsAt: startsAt,
        endsAt: endsAt,
        reason: _reason.text,
      ),
    );
    if (!mounted || result == LeaveMutationResult.stale) return;
    if (result == LeaveMutationResult.success) {
      ToastService.success(context, message: 'Leave request submitted');
      Navigator.pop(context);
    } else if (result == LeaveMutationResult.failure) {
      ToastService.error(
        context,
        message: cubit.state.failure?.message ?? 'Could not submit request',
      );
    }
  }
}
