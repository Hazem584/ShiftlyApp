import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/utils/work_duration.dart';

void main() {
  test('formats hours, fractional hours and overtime without rounding away minutes', () {
    expect(workDuration(480), '8 h');
    expect(workDuration(500), '8 h 20 min');
    expect(workDurationWithOvertime(435, 15), '7 h 15 min · 15 min overtime');
    expect(
      workDurationWithOvertime(435, 15, arabic: true),
      '7 ساعة و15 دقيقة · 15 دقيقة وقت إضافي',
    );
  });
}
