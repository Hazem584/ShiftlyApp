import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('Cairo week stays Saturday across the October 2026 clock change', () {
    final cairo = WorkspaceTime.location('Africa/Cairo');
    // Adding 96 hours to Tuesday midnight lands on Friday at 23:00.
    final tuesday = tz.TZDateTime(cairo, 2026, 10, 27);
    expect(tuesday.add(const Duration(days: 4)).weekday, DateTime.friday);
    for (var day = 25; day <= 31; day++) {
      expect(
        WorkspaceTime.nextSaturdayDateKey(
          tz.TZDateTime(cairo, 2026, 10, day),
          'Africa/Cairo',
        ),
        '2026-10-31',
      );
    }
  });
  test('Cairo spring clock change preserves the calendar date', () {
    expect(
      WorkspaceTime.nextSaturdayDateKey(
        DateTime.utc(2026, 4, 21, 12),
        'Africa/Cairo',
      ),
      '2026-04-25',
    );
  });
  test('Saturday stays in the same planning week', () {
    expect(
      WorkspaceTime.nextSaturdayDateKey(
        DateTime.utc(2026, 10, 31, 12),
        'Africa/Cairo',
      ),
      '2026-10-31',
    );
  });
  test('workspace date, rather than UTC date, decides the week', () {
    final instant = DateTime.utc(2026, 10, 31, 23);
    expect(
      WorkspaceTime.nextSaturdayDateKey(instant, 'Africa/Cairo'),
      '2026-11-07',
    );
    expect(
      WorkspaceTime.nextSaturdayDateKey(instant, 'America/New_York'),
      '2026-10-31',
    );
  });
  test('planning week rolls into the next year', () {
    expect(
      WorkspaceTime.nextSaturdayDateKey(
        DateTime.utc(2026, 12, 31, 12),
        'Africa/Cairo',
      ),
      '2027-01-02',
    );
  });
}
