import 'report_metrics.dart';

class ReportEmployeeRow {
  const ReportEmployeeRow(
    this.employee,
    this.metrics, {
    this.fullMonth = true,
    this.payrollDays,
  });

  final ReportEmployee employee;
  final ReportMetrics metrics;
  final bool fullMonth;
  final ({int absent, int leave})? payrollDays;
  int get absentDays => payrollDays?.absent ?? metrics.absentDays;

  double get hourlyRate => employee.hourlyRate ?? 0;
  double get basePay {
    final salary = employee.monthlySalary;
    if (salary != null) {
      if (fullMonth) return salary;
      return (metrics.attendanceDays +
              (payrollDays?.leave ?? metrics.paidLeaveDays)) *
          employee.dailyRate;
    }
    final regularMinutes =
        metrics.workMinutes - metrics.extraMinutes - metrics.excessMinutes;
    return (regularMinutes < 0 ? 0 : regularMinutes) / 60 * hourlyRate;
  }

  double get deductions => fullMonth ? absentDays * employee.dailyRate : 0;
  double get overtimePay =>
      (metrics.extraMinutes + metrics.excessMinutes) / 60 * hourlyRate;
  double get netPay =>
      (basePay - deductions + overtimePay).clamp(0.0, double.infinity);
}
