import 'package:shiftly/core/session/feature_scope.dart';

import 'extra_authorization.dart';
import 'extra_authorization_page.dart';

abstract interface class ExtraShiftRepository {
  Future<ExtraAuthorizationPage> listExtras(
    String workspaceId,
    String membershipId, {
    int page = 1,
    int limit = 20,
  });
  Future<ExtraAuthorization> createExtra(
    String workspaceId,
    String membershipId,
    Map<String, Object?> payload, {
    required bool actual,
  });
  Future<ExtraAuthorization> revokeExtra(
    String workspaceId,
    String membershipId,
    String authorizationId,
  );
  Future<String?> readExtraIntent(FeatureSessionScope scope);
  Future<void> saveExtraIntent(FeatureSessionScope scope, String intent);
  Future<void> clearExtraIntent(FeatureSessionScope scope, String intent);
}
