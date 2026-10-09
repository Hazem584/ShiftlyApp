import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';

class ExtraShiftsState {
  const ExtraShiftsState({
    this.loading = true,
    this.busy = false,
    this.recoveryBlocked = true,
    this.page,
    this.intent,
    this.canonical,
    this.failure,
  });
  final bool loading, busy, recoveryBlocked;
  final ExtraAuthorizationPage? page;
  final ExtraShiftIntent? intent;
  final ExtraAuthorization? canonical;
  final Failure? failure;
}
