import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shift_cubit_helpers.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_restorer.dart';

Future<void> loadFlexibleAttendance(
  FlexibleAttendanceHost host, {
  required bool refresh,
  required int revision,
}) async {
  final scope = host.scope;
  if (scope == null || host.busy) return;
  final generation = host.generation;
  final previous = host.state;
  host.emitState(
    previous.copyWith(
      loading: previous.eligibility == null,
      refreshing: refresh,
      recoveryBlocked: true,
      clearFailure: true,
    ),
  );
  try {
    final values = await Future.wait<Object?>([
      restoreFlexibleAttendance(host, scope, generation, revision),
      host.repository.getEligibility(scope.workspaceId),
      host.repository.listMyTemplates(scope.workspaceId).then<void>((page) {
        if (!host.current(scope, generation, revision)) return;
        if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
          throw const FormatException('Cross-scope schedule');
        }
        host.emitState(host.state.copyWith(templates: page.data));
      }),
    ]);
    if (!host.current(scope, generation, revision)) return;
    final eligibility = values[1] as TemplateEligibility;
    if (eligibility.workspaceId != scope.workspaceId ||
        eligibility.authorizedOccurrences.any(
          (v) => v.template.workspaceId != scope.workspaceId,
        )) {
      throw const FormatException('Cross-scope attendance');
    }
    host.emitState(
      FlexibleAttendanceState(
        loading: false,
        recovery: host.state.recovery,
        legacyReviews: host.state.legacyReviews,
        recoveryBlocked: host.state.recoveryBlocked,
        current: host.state.current,
        eligibility: eligibility,
        templates: host.state.templates,
      ),
    );
  } catch (error) {
    if (host.current(scope, generation, revision)) {
      host.emitState(
        host.state.copyWith(
          loading: false,
          refreshing: false,
          recoveryBlocked: true,
          failure: fixedShiftFailure(
            error,
            'Unable to load attendance. Restore access and refresh; saved operations are retained.',
          ),
        ),
      );
    }
  }
}
