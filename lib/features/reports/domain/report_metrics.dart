class ReportEmployee {
  const ReportEmployee(
    this.id,
    this.name, {
    this.monthlySalary,
    this.hourlyRate,
  });
  final String id, name;
  final double? monthlySalary, hourlyRate;
  double effectiveHourlyRate([int standardHours = 176]) =>
      hourlyRate ??
      (monthlySalary != null && standardHours > 0
          ? monthlySalary! / standardHours
          : 0);
}

class ReportMetrics {
  const ReportMetrics({
    this.attendanceDays = 0,
    this.absentDays = 0,
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

class ReportEmployeeRow {
  const ReportEmployeeRow(this.employee, this.metrics);
  final ReportEmployee employee;
  final ReportMetrics metrics;

  double get hourlyRate => employee.effectiveHourlyRate();
  double get basePay =>
      employee.monthlySalary ??
      ((metrics.workMinutes - metrics.extraMinutes - metrics.excessMinutes)
              .clamp(0, 1000000) /
          60.0 *
          hourlyRate);
  double get deductions =>
      (((metrics.lateMinutes + metrics.earlyLeaveMinutes) / 60.0) *
          hourlyRate) +
      (metrics.absentDays *
          (employee.monthlySalary != null
              ? employee.monthlySalary! / 30.0
              : hourlyRate * 8.0));
  double get overtimePay =>
      ((metrics.extraMinutes + metrics.excessMinutes) / 60.0) *
      hourlyRate *
      1.5;
  double get netPay =>
      (basePay - deductions + overtimePay).clamp(0.0, double.infinity);
}
