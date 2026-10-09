import 'package:shiftly/core/error/failure.dart';

import '../../data/extra_authorization.dart';
import '../../data/extra_authorization_page.dart';
import '../../data/extra_shift_intent.dart';

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
