import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

void main() {
  test('workspace wall time round-trips through UTC using IANA timezone', () {
    final utc = WorkspaceTime.wallTimeToUtc(
      date: DateTime(2026, 9, 26),
      hour: 8,
      minute: 30,
      timezoneName: 'Africa/Cairo',
    );
    expect(utc, DateTime.utc(2026, 9, 26, 5, 30));
    final local = WorkspaceTime.inWorkspace(utc, 'Africa/Cairo');
    expect(
      (local.year, local.month, local.day, local.hour, local.minute),
      (2026, 9, 26, 8, 30),
    );
  });

  test('unknown timezone falls back safely to UTC', () {
    final local = WorkspaceTime.inWorkspace(
      DateTime.utc(2026, 9, 26, 8),
      'Invalid/Timezone',
    );
    expect(local.hour, 8);
    expect(local.timeZoneName, 'UTC');
  });

  test('IANA conversion observes daylight-saving boundaries', () {
    final winter = WorkspaceTime.wallTimeToUtc(
      date: DateTime(2026, 1, 15),
      hour: 9,
      minute: 0,
      timezoneName: 'America/New_York',
    );
    final summer = WorkspaceTime.wallTimeToUtc(
      date: DateTime(2026, 7, 15),
      hour: 9,
      minute: 0,
      timezoneName: 'America/New_York',
    );
    expect(winter.hour, 14);
    expect(summer.hour, 13);
  });
}
