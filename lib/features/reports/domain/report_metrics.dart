export 'report_employee_row.dart';

class ReportEmployee {
  const ReportEmployee(
    this.id,
    this.name, {
    this.monthlySalary,
    this.hourlyRate,
    this.payrollWorkDays = 26,
  });
  final String id, name;
  final double? monthlySalary, hourlyRate;
  final int payrollWorkDays;
  double get dailyRate =>
      (monthlySalary ?? 0) / (payrollWorkDays <= 0 ? 26 : payrollWorkDays);
}

class ReportMetrics {
  const ReportMetrics({
    this.attendanceDays = 0,
    this.absentDays = 0,
    this.paidLeaveDays = 0,
    this.approved = 0,
    this.pending = 0,
    this.rejected = 0,
    this.unknown = 0,
    this.open = 0,
    this.late = 0,
    this.lateMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.workMinutes = 0,
    this.extraMinutes = 0,
    this.excessMinutes = 0,
    this.missingSchedule = 0,
    this.missingWorkMinutes = 0,
  });

  final int attendanceDays,
      absentDays,
      paidLeaveDays,
      approved,
      pending,
      rejected,
      unknown,
      open,
      late,
      lateMinutes,
      earlyLeaveMinutes,
      workMinutes,
      extraMinutes,
      excessMinutes,
      missingSchedule,
      missingWorkMinutes;

  ReportMetrics operator +(ReportMetrics other) => ReportMetrics(
    attendanceDays: attendanceDays + other.attendanceDays,
    absentDays: absentDays + other.absentDays,
    paidLeaveDays: paidLeaveDays + other.paidLeaveDays,
    approved: approved + other.approved,
    pending: pending + other.pending,
    rejected: rejected + other.rejected,
    unknown: unknown + other.unknown,
    open: open + other.open,
    late: late + other.late,
    lateMinutes: lateMinutes + other.lateMinutes,
    earlyLeaveMinutes: earlyLeaveMinutes + other.earlyLeaveMinutes,
    workMinutes: workMinutes + other.workMinutes,
    extraMinutes: extraMinutes + other.extraMinutes,
    excessMinutes: excessMinutes + other.excessMinutes,
    missingSchedule: missingSchedule + other.missingSchedule,
    missingWorkMinutes: missingWorkMinutes + other.missingWorkMinutes,
  );
}
