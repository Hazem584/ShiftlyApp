import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/models/shift.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

void main() {
  test('midnight, noon and afternoon use h:mm a, including English GB', () {
    expect(ClockTime.format(0, 0, locale: 'en'), '12:00 AM');
    expect(ClockTime.format(12, 0, locale: 'en'), '12:00 PM');
    expect(ClockTime.format(15, 30, locale: 'en'), '3:30 PM');
    expect(ClockTime.format(8, 0, locale: 'en_GB'), '8:00 AM');
  });

  test('other locales use localized AM/PM labels', () {
    expect(ClockTime.format(8, 0, locale: 'ar'), endsWith('ص'));
    expect(ClockTime.format(15, 30, locale: 'ar'), endsWith('م'));
    expect(ClockTime.format(15, 30, locale: 'unknown'), '3:30 PM');
  });

  test('overnight clock ranges do not change dates or minute values', () {
    const startMinute = 1380;
    const endMinute = 360;
    expect(
      '${ClockTime.minutes(startMinute)} – ${ClockTime.minutes(endMinute)}',
      '11:00 PM – 6:00 AM',
    );
    final start = DateTime(2026, 10, 8, 23);
    final end = DateTime(2026, 10, 9, 6);
    final shift = Shift(
      id: 'fixture',
      name: 'Overnight',
      startTime: start,
      endTime: end,
    );
    expect(shift.timeRange, '11:00 PM – 6:00 AM');
    expect(shift.endTime.difference(shift.startTime), const Duration(hours: 7));
    expect(startMinute, 1380);
    expect(endMinute, 360);
  });

  test(
    'workspace conversions retain IANA zones and daylight-saving transitions',
    () {
      expect(
        WorkspaceTime.time(DateTime.utc(2026, 1, 2, 5), 'America/New_York'),
        '12:00 AM EST',
      );
      expect(
        WorkspaceTime.dateTime(
          DateTime.utc(2026, 1, 2, 17),
          'America/New_York',
        ),
        '2026-01-02 12:00 PM EST',
      );
      expect(
        WorkspaceTime.time(DateTime.utc(2026, 3, 8, 6, 30), 'America/New_York'),
        '1:30 AM EST',
      );
      expect(
        WorkspaceTime.time(DateTime.utc(2026, 3, 8, 7, 30), 'America/New_York'),
        '3:30 AM EDT',
      );
      final utc = WorkspaceTime.wallTimeToUtc(
        date: DateTime(2026, 1, 2),
        hour: 15,
        minute: 30,
        timezoneName: 'America/New_York',
      );
      expect(utc.toIso8601String(), '2026-01-02T20:30:00.000Z');
      expect(
        WorkspaceTime.time(utc, 'America/New_York', locale: 'ar'),
        contains('م'),
      );
      expect(WorkspaceTime.time(null, 'Etc/UTC'), 'Not recorded');
    },
  );

  testWidgets('picker ignores 24-hour device preference and preserves values', (
    tester,
  ) async {
    TimeOfDay? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await ClockTimePicker.show(
                    context: context,
                    initialTime: const TimeOfDay(hour: 15, minute: 30),
                  );
                },
                child: const Text('Pick'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(
      MediaQuery.alwaysUse24HourFormatOf(
        tester.element(find.byType(TimePickerDialog)),
      ),
      isFalse,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(selected, const TimeOfDay(hour: 15, minute: 30));
  });

  testWidgets('overnight labels wrap in a narrow scaled layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${ClockTime.minutes(1380)} – ${ClockTime.minutes(360)} (overnight)',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('11:00 PM – 6:00 AM (overnight)'), findsOneWidget);
  });
}
