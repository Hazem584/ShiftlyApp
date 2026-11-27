class ReportEmployee {
  const ReportEmployee(this.id, this.name);
  final String id, name;
}

class ReportMetrics {
  const ReportMetrics({
    this.attendanceDays = 0,
    this.approved = 0,
    this.pending = 0,
    this.rejected = 0,
    this.unknown = 0,
    this.open = 0,
    this.late = 0,
    this.lateMinutes = 0,
    this.workMinutes = 0,
    this.extraMinutes = 0,
    this.excessMinutes = 0,
    this.missingSchedule = 0,
    this.missingWorkMinutes = 0,
  });

  final int attendanceDays,
      approved,
      pending,
      rejected,
      unknown,
      open,
      late,
      lateMinutes,
      workMinutes,
      extraMinutes,
      excessMinutes,
      missingSchedule,
      missingWorkMinutes;

  ReportMetrics operator +(ReportMetrics other) => ReportMetrics(
    attendanceDays: attendanceDays + other.attendanceDays,
    approved: approved + other.approved,
    pending: pending + other.pending,
    rejected: rejected + other.rejected,
    unknown: unknown + other.unknown,
    open: open + other.open,
    late: late + other.late,
    lateMinutes: lateMinutes + other.lateMinutes,
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
}
