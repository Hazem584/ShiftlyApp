import 'package:equatable/equatable.dart';
import 'package:shiftly/core/models/attendance_record.dart';
import 'package:shiftly/core/models/shift.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.totalEmployees,
    required this.presentEmployees,
    required this.absentEmployees,
    required this.lateEmployees,
    required this.pendingRequests,
    required this.recentActivity,
    required this.currentShift,
    required this.currentShiftEmployees,
  });

  final int totalEmployees;
  final int presentEmployees;
  final int absentEmployees;
  final int lateEmployees;
  final int pendingRequests;
  final List<AttendanceRecord> recentActivity;
  final Shift currentShift;
  final int currentShiftEmployees;

  bool get isEmpty => totalEmployees == 0;

  @override
  List<Object?> get props => [
    totalEmployees,
    presentEmployees,
    absentEmployees,
    lateEmployees,
    pendingRequests,
    recentActivity,
    currentShift,
    currentShiftEmployees,
  ];
}

abstract interface class DashboardRepository {
  Future<DashboardData> getDashboard();
}
