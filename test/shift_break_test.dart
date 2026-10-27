import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/breaks/domain/break_notifier.dart';

class Notices implements BreakNotifier {
  DateTime? scheduled;
  int cancelled = 0;
  bool allowed = true;
  Completer<bool>? pending;
  @override
  Future<bool> scheduleBreak(DateTime end, {required bool arabic}) async {
    scheduled = end;
    return pending == null ? allowed : pending!.future;
  }

  @override
  Future<void> cancelBreak() async {
    cancelled++;
    scheduled = null;
  }
}

void main() {
  late DateTime now;
  late SharedPreferences prefs;
  late Notices notices;
  late ShiftBreakController controller;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 10, 26, 8);
    notices = Notices();
    controller =
        ShiftBreakController(
            preferences: prefs,
            notifier: notices,
            now: () => now,
          )
          ..bind('owner')
          ..restore('shift-1');
  });
  tearDown(() => controller.dispose());
  test('one hour survives restart and never restarts after expiry', () async {
    expect(await controller.start(arabic: true), isTrue);
    expect(notices.scheduled, now.add(const Duration(hours: 1)));
    now = now.add(const Duration(minutes: 25));
    final reopened =
        ShiftBreakController(
            preferences: prefs,
            notifier: notices,
            now: () => now,
          )
          ..bind('owner')
          ..restore('shift-1');
    expect(reopened.remaining, const Duration(minutes: 35));
    expect(await reopened.start(arabic: true), isFalse);
    now = now.add(const Duration(minutes: 35));
    expect(reopened.running, isFalse);
    expect(reopened.used, isTrue);
    expect(await reopened.start(arabic: false), isFalse);
    reopened.dispose();
  });
  test(
    'ending early cancels only the break and retains the used allowance',
    () async {
      await controller.start(arabic: false);
      await controller.finish();
      expect(controller.running, isFalse);
      expect(controller.used, isTrue);
      expect(notices.scheduled, isNull);
      expect(await controller.start(arabic: false), isFalse);
    },
  );
  test('denied notifications preserve the local timer honestly', () async {
    notices.allowed = false;
    expect(await controller.start(arabic: true), isTrue);
    expect(controller.running, isTrue);
    expect(controller.notificationScheduled, isFalse);
  });
  test('shifts and accounts do not share break allowance', () async {
    await controller.start(arabic: false);
    controller.restore('shift-2');
    expect(controller.used, isFalse);
    controller.restore('shift-1');
    expect(controller.used, isTrue);
    controller.bind('other');
    controller.restore('shift-1');
    expect(controller.used, isFalse);
    await controller.start(arabic: false);
    expect(controller.running, isTrue);
  });
  test('sign out invalidates a notification being installed', () async {
    notices.pending = Completer<bool>();
    final starting = controller.start(arabic: false);
    while (notices.scheduled == null) {
      await Future<void>.delayed(Duration.zero);
    }
    controller.bind(null);
    notices.pending!.complete(true);
    expect(await starting, isFalse);
    await controller.finish();
    expect(controller.running, isFalse);
    expect(notices.scheduled, isNull);
  });
}
