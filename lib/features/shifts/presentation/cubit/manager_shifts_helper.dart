import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_state.dart';

class ManagerShiftsHelper {
  static Failure? validateShift({
    required DateTime startsAt,
    required DateTime endsAt,
    required int breakMinutes,
    required int graceMinutes,
  }) {
    if (!endsAt.isAfter(startsAt)) {
      return const Failure(
        message: 'Shift end must be after its start.',
        kind: FailureKind.validation,
      );
    }
    final duration = endsAt.difference(startsAt).inMinutes;
    if (duration > 1440) {
      return const Failure(
        message: 'Shift duration cannot exceed 24 hours.',
        kind: FailureKind.validation,
      );
    }
    if (breakMinutes < 0 || breakMinutes > 1440 || breakMinutes >= duration) {
      return const Failure(
        message: 'Break must be shorter than the shift.',
        kind: FailureKind.validation,
      );
    }
    if (graceMinutes < 0 || graceMinutes > 1440) {
      return const Failure(
        message: 'Grace minutes must be between 0 and 1440.',
        kind: FailureKind.validation,
      );
    }
    return null;
  }

  static Failure? validateUpdate(
    ManagerShiftsState state,
    String shiftId,
    UpdateShiftInput input,
  ) {
    final current = state.records.where((i) => i.id == shiftId).firstOrNull;
    final startsAt = input.startsAt ?? current?.startsAt;
    final endsAt = input.endsAt ?? current?.endsAt;
    final breakMinutes = input.breakMinutes ?? current?.breakMinutes;
    final graceMinutes = input.graceMinutes ?? current?.graceMinutes;
    if (startsAt == null ||
        endsAt == null ||
        breakMinutes == null ||
        graceMinutes == null) {
      return const Failure(message: 'Missing shift timing.');
    }
    return validateShift(
      startsAt: startsAt,
      endsAt: endsAt,
      breakMinutes: breakMinutes,
      graceMinutes: graceMinutes,
    );
  }

  static List<ShiftRecord> upsert(
    List<ShiftRecord> records,
    ShiftRecord record,
  ) {
    final values = [record, ...records.where((item) => item.id != record.id)];
    values.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return values;
  }

  static Failure failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);

  static Failure invalidResponse() => const Failure(
    message: 'The server returned an invalid shift response.',
    kind: FailureKind.server,
  );
}
