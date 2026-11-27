import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_actions.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_fields.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_form_surface.dart';

class LeaveRequestFormDialog extends StatefulWidget {
  const LeaveRequestFormDialog({required this.timezone, super.key});
  final String timezone;

  @override
  State<LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}

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
  Widget build(BuildContext context) => EmployeeFormSurface(
    title: Text(context.tr('Request time off')),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: buildLeaveRequestFormFields(
            context: context,
            type: _type,
            startDate: _startDate,
            endDate: _endDate,
            startTime: _startTime,
            endTime: _endTime,
            reasonController: _reason,
            onTypeChanged: (value) => setState(() {
              _type = value ?? _type;
              if (_type == LeaveRequestType.earlyLeave) _endDate = _startDate;
            }),
            onPickStartDate: () => _pickDate(start: true),
            onPickEndDate: () => _pickDate(start: false),
            onPickStartTime: () => _pickTime(start: true),
            onPickEndTime: () => _pickTime(start: false),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      BlocBuilder<EmployeeLeaveRequestsCubit, EmployeeLeaveRequestsState>(
        buildWhen: (p, c) => p.creating != c.creating,
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
              : Text(context.tr('Submit request')),
        ),
      ),
    ],
  );

  Future<void> _pickDate({required bool start}) async {
    final picked = await pickLeaveRequestDate(
      context: context,
      timezone: widget.timezone,
      initialDate: start ? _startDate : _endDate,
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
    final picked = await ClockTimePicker.show(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => start ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    await submitLeaveRequestForm(
      context: context,
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
      startTime: _startTime,
      endTime: _endTime,
      timezone: widget.timezone,
      reason: _reason.text,
    );
  }
}
