import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/models/attendance_status_summary.dart';

final _date = DateTime.utc(2030, 1, 1, 9);
final _template = ShiftTemplate(
  id: 'template',
  workspaceId: 'workspace',
  name: 'Morning',
  color: '#334155',
  startMinute: 540,
  endMinute: 1020,
  graceMinutes: 10,
  allowedEarlyCheckInMinutes: 30,
  allowedLateCheckInMinutes: 60,
  minimumWorkMinutes: 420,
  active: true,
  overnight: false,
  createdAt: _date,
  updatedAt: _date,
);

EligibleShiftOccurrence _entry({
  bool eligible = true,
  bool used = false,
  String? assignment = 'assignment',
  DateTime? opens,
}) => EligibleShiftOccurrence(
  occurrenceKind: 'BASELINE',
  assignmentId: assignment,
  timezone: 'Etc/UTC',
  eligible: eligible,
  alreadyUsed: used,
  template: _template,
  operationalDate: '2030-01-01',
  scheduledStartAt: _date,
  scheduledEndAt: _date.add(const Duration(hours: 8)),
  checkInWindowStart: opens ?? _date.subtract(const Duration(minutes: 30)),
  checkInWindowEnd: _date.add(const Duration(hours: 1)),
  classification: AttendanceClassification.onTime,
  lateMinutes: 0,
  recommended: true,
);

FlexibleAttendanceState _state(EligibleShiftOccurrence entry) =>
    FlexibleAttendanceState(
      loading: false,
      eligibility: TemplateEligibility(
        workspaceId: 'workspace',
        timezone: 'Etc/UTC',
        evaluatedAt: _date,
        recommended: null,
        eligibleTemplates: [],
        authorizedOccurrences: [entry],
      ),
    );

void main() {
  test('ready status requires backend authorization and unused occurrence', () {
    expect(
      AttendanceStatusSummary.fromState(_state(_entry())).tone,
      AttendanceStatusTone.ready,
    );
    for (final entry in [
      _entry(eligible: false),
      _entry(used: true),
      _entry(assignment: null),
    ]) {
      expect(
        AttendanceStatusSummary.fromState(_state(entry)).tone,
        isNot(AttendanceStatusTone.ready),
      );
    }
  });

  test('saved uncertain write takes priority over an available new shift', () {
    final state = _state(_entry()).copyWith(
      recovery: const PendingClockIn(
        userId: 'user',
        workspaceId: 'workspace',
        membershipId: 'member',
        templateId: 'template',
        clientAttendanceId: 'saved-request',
      ),
    );
    final summary = AttendanceStatusSummary.fromState(state);
    expect(summary.tone, AttendanceStatusTone.attention);
    expect(summary.occurrence, isNull);
    expect(summary.message, contains('before starting another'));
  });

  test('failed or blocked status checks never advertise a ready shift', () {
    for (final state in [
      _state(_entry()).copyWith(failure: const Failure(message: 'Offline')),
      _state(_entry()).copyWith(recoveryBlocked: true),
      _state(_entry()).copyWith(refreshing: true),
      const FlexibleAttendanceState(loading: false),
    ]) {
      expect(
        AttendanceStatusSummary.fromState(state).tone,
        isNot(AttendanceStatusTone.ready),
      );
      expect(AttendanceStatusSummary.fromState(state).occurrence, isNull);
    }
  });

  test('upcoming information uses server evaluation time without permitting clock-in', () {
    final entry = _entry(
      eligible: false,
      opens: _date.add(const Duration(minutes: 15)),
    );
    final summary = AttendanceStatusSummary.fromState(_state(entry));
    expect(summary.title, 'Your next check-in window');
    expect(summary.occurrence, entry);
    expect(summary.tone, AttendanceStatusTone.neutral);
  });

  test('active attendance remains visible after a failed refresh with stale status explanation', () {
    final attendance = FlexibleAttendance(
      id: 'attendance',
      workspaceId: 'workspace',
      employeeMembershipId: 'member',
      source: AttendanceSource.template,
      classification: AttendanceClassification.onTime,
      clockInAt: _date,
      minutesLate: 0,
      createdAt: _date,
      updatedAt: _date,
    );
    final summary = AttendanceStatusSummary.fromState(
      _state(_entry()).copyWith(
        current: attendance,
        failure: const Failure(message: 'Offline'),
      ),
    );
    expect(summary.tone, AttendanceStatusTone.active);
    expect(summary.message, contains('last confirmed'));
    expect(summary.occurrence, isNull);
  });
}
