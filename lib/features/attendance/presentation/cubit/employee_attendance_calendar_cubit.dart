import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';

class EmployeeAttendanceCalendarCubit extends AttendanceCalendarCubit {
  EmployeeAttendanceCalendarCubit(super.repository) : super(employee: true);
}
