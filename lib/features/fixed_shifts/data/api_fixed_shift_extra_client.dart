import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_attendance_client.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_parsers.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_template_client.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_intent_store.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/legacy_clock_in_repository.dart';

abstract class ApiFixedShiftExtraAndIntentClient
    extends ApiFixedShiftTemplateClient
    implements ExtraShiftRepository, LegacyClockInRepository {
  FixedShiftIntentStore get intents;

  @override
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) => intents.loadPendingClockIn(
    userId: userId,
    workspaceId: workspaceId,
    membershipId: membershipId,
    templateId: templateId,
  );

  @override
  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  ) => intents.inspectLegacyClockIns(scope);

  @override
  Future<FlexibleAttendance?> findPendingAttendance(PendingClockIn value) =>
      fetchPendingAttendance(dio, value);
  @override
  Future<void> savePendingClockIn(PendingClockIn value) =>
      intents.savePendingClockIn(value);
  @override
  Future<void> clearPendingClockIn(PendingClockIn value) =>
      intents.clearPendingClockIn(value);
  @override
  Future<ExtraAuthorizationPage> listExtras(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  }) => fetchExtraAuthorizations(
    dio,
    workspaceId,
    membershipId,
    page: page,
    limit: limit,
  );
  @override
  Future<ExtraAuthorization> createExtra(
    String workspaceId,
    String membershipId,
    Map<String, Object?> payload, {
    required bool actual,
  }) => postExtraAuthorization(
    dio,
    workspaceId,
    membershipId,
    payload,
    actual: actual,
  );
  @override
  Future<ExtraAuthorization> revokeExtra(
    String workspaceId,
    String membershipId,
    String authorizationId,
  ) => requestFixedShift(() async {
    final res = await dio.delete<Object?>(
      '/workspaces/$workspaceId/employees/$membershipId/extra-shifts/$authorizationId',
    );
    return ExtraAuthorization(ApiModelParser.map(res.data));
  });
  @override
  Future<String?> readExtraIntent(FeatureSessionScope scope) =>
      intents.readExtraIntent(scope);
  @override
  Future<void> saveExtraIntent(FeatureSessionScope scope, String intent) =>
      intents.saveExtraIntent(scope, intent);
  @override
  Future<void> clearExtraIntent(FeatureSessionScope scope, String intent) =>
      intents.clearExtraIntent(scope, intent);
}
