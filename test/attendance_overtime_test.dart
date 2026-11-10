import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/attendance/domain/services/attendance_overtime.dart';

DateTime at(String time) => DateTime.parse('2026-11-09T$time:00Z');
void main() {
  test('credits unused break only at shift end for on-time attendance', () {
    int overtime(String arrival, String departure) => attendanceOvertimeMinutes(
      clockIn: at(arrival),
      clockOut: at(departure),
      scheduledStart: at('08:30'),
      scheduledEnd: at('17:00'),
      unusedBreakSeconds: 1800,
    );
    expect(overtime('08:30', '16:59'), 0);
    expect(overtime('08:30', '17:00'), 30);
    expect(overtime('08:30', '17:15'), 45);
    expect(overtime('08:35', '18:09'), 64);
  });

  test('reported shift produces 64 minutes, without an unused break bonus', () {
    expect(
      attendanceOvertimeMinutes(
        clockIn: at('08:35'),
        clockOut: at('18:09'),
        scheduledStart: at('08:30'),
        scheduledEnd: at('17:00'),
      ),
      64,
    );
  });
  test('late time must be made up before overtime starts', () {
    expect(
      attendanceOvertimeMinutes(
        clockIn: at('09:30'),
        clockOut: at('17:15'),
        scheduledStart: at('08:30'),
        scheduledEnd: at('17:00'),
      ),
      0,
    );
  });
  test('early attendance and an ordinary finish produce no overtime', () {
    expect(
      attendanceOvertimeMinutes(
        clockIn: at('08:00'),
        clockOut: at('17:00'),
        scheduledStart: at('08:30'),
        scheduledEnd: at('17:00'),
      ),
      0,
    );
  });
  test('overnight shifts use full instants', () {
    expect(
      attendanceOvertimeMinutes(
        clockIn: at('22:05'),
        clockOut: DateTime.parse('2026-11-10T07:09:00Z'),
        scheduledStart: at('22:00'),
        scheduledEnd: DateTime.parse('2026-11-10T06:00:00Z'),
      ),
      64,
    );
  });
}
