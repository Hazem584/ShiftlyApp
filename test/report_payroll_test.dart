import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';

void main() {
  const employee = ReportEmployee(
    'employee',
    'Employee',
    monthlySalary: 8000,
    hourlyRate: 50,
    payrollWorkDays: 26,
  );

  test('monthly salary uses the contract divisor for an unpaid absence', () {
    const row = ReportEmployeeRow(
      employee,
      ReportMetrics(lateMinutes: 15, excessMinutes: 60),
      payrollDays: (absent: 1, leave: 4),
    );
    expect(employee.dailyRate, closeTo(307.6923, 0.0001));
    expect(row.basePay, 8000);
    expect(row.deductions, closeTo(307.6923, 0.0001));
    expect(row.overtimePay, 50);
    expect(row.netPay, closeTo(7742.3077, 0.0001));
  });

  test(
    'partial reports pay only attendance and paid leave at the daily rate',
    () {
      const row = ReportEmployeeRow(
        employee,
        ReportMetrics(attendanceDays: 3),
        fullMonth: false,
        payrollDays: (absent: 1, leave: 1),
      );
      expect(row.basePay, closeTo(4 * 8000 / 26, 0.0001));
      expect(row.deductions, 0);
    },
  );
}
