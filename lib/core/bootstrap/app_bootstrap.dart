import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/network/api_client.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDependencies {
  const AppDependencies({required this.sessionCoordinator});

  final SessionCoordinator sessionCoordinator;
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
    return AppDependencies(sessionCoordinator: coordinator);
  }
}
