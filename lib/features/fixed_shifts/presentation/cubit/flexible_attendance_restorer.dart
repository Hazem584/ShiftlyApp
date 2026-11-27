import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/legacy_clock_in_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/flexible_attendance_host.dart';

Future<void> restoreFlexibleAttendance(
  FlexibleAttendanceHost host,
  FeatureSessionScope scope,
  int generation,
  int revision,
) async {
  final restored = await host.repository.getCurrentAttendance(
    scope.workspaceId,
  );
  if (!host.current(scope, generation, revision)) return;
  if (restored != null &&
      (restored.workspaceId != scope.workspaceId ||
          restored.employeeMembershipId != scope.membershipId)) {
    throw const FormatException('Cross-scope attendance');
  }
  host.emitState(
    host.state.copyWith(
      current: restored,
      clearCurrent: restored == null && host.state.current?.isOpen != false,
    ),
  );
  final pending = await host.repository.loadPendingClockIn(
    userId: scope.userId,
    workspaceId: scope.workspaceId,
    membershipId: scope.membershipId,
    templateId: '',
  );
  if (!host.current(scope, generation, revision)) return;
  host.emitState(
    host.state.copyWith(
      recovery: pending,
      clearRecovery: pending == null,
      recoveryBlocked: true,
    ),
  );
  final legacyRepo = host.repository;
  final reviews = legacyRepo is LegacyClockInRepository
      ? await (legacyRepo as LegacyClockInRepository).inspectLegacyClockIns(
          scope,
        )
      : <LegacyClockInReview>[];
  if (!host.current(scope, generation, revision)) return;
  host.emitState(
    host.state.copyWith(
      legacyReviews: reviews,
      recoveryBlocked: pending != null || reviews.any((v) => v.requiresReview),
    ),
  );
}
