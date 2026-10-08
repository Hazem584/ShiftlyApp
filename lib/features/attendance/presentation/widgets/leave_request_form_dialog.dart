import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_display.dart';

part 'parts/leave_request_form_dialog/private_leave_request_form_dialog_state.dart';
part 'parts/leave_request_form_dialog/private_date_button.dart';
part 'parts/leave_request_form_dialog/private_time_button.dart';

class LeaveRequestFormDialog extends StatefulWidget {
  const LeaveRequestFormDialog({required this.timezone, super.key});
  final String timezone;

  @override
  State<LeaveRequestFormDialog> createState() => _LeaveRequestFormDialogState();
}
