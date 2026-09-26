import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/network/api_client.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/profile/data/api_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDependencies {
  const AppDependencies({
    required this.sessionCoordinator,
    required this.profileRepository,
  });

  final SessionCoordinator sessionCoordinator;
  final ProfileRepository profileRepository;
}

abstract final class AppBootstrap {
  static Future<AppDependencies> initialize() async {
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl.toString(),
      publishableKey: config.supabasePublishableKey,
    );
    final preferences = await SharedPreferences.getInstance();
    final workspaceStorage = SharedPreferencesActiveWorkspaceStorage(
      preferences,
    );
    final authentication = SupabaseAuthenticationService(
      Supabase.instance.client.auth,
    );
    final apiClient = ApiClient(
      config: config,
      authentication: authentication,
      workspaceStorage: workspaceStorage,
    );
    final coordinator = SessionCoordinator(
      authentication,
      AuthenticationApiRepository(apiClient.dio),
      workspaceStorage,
    );
    final profileRepository = ApiProfileRepository(
      apiClient.dio,
      () => coordinator.state.activeMembership,
      currentUser: () => coordinator.state.currentUser,
    );
    return AppDependencies(
      sessionCoordinator: coordinator,
      profileRepository: profileRepository,
    );
  }
}
