import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/preferences_language_store.dart';
import 'package:shiftly/core/network/api_client.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/core/offline/saved_read_interceptor.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/core/theme/preferences_theme_store.dart';
import 'package:shiftly/core/theme/theme_preference_store.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/onboarding/data/preferences_onboarding_storage.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerCoreProductionDependencies(
  GetIt t,
  AppConfig config,
  SharedPreferences prefs,
  ChatCacheDatabase chatStorage,
) {
  t
    ..registerSingleton<ChatCacheDatabase>(chatStorage, dispose: (s) => s.close())
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<SupabaseClient>(Supabase.instance.client)
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<SavedReadStore>(SavedReadStore(prefs))
    ..registerLazySingleton<ReadSyncCubit>(
      () => ReadSyncCubit(t()),
      dispose: (c) => c.close(),
    )
    ..registerSingleton<ThemePreferenceStore>(PreferencesThemeStore(prefs))
    ..registerSingleton<LanguagePreferenceStore>(PreferencesLanguageStore(prefs))
    ..registerLazySingleton<OnboardingStorage>(() => PreferencesOnboardingStorage(t()))
    ..registerLazySingleton<ActiveWorkspaceStorage>(
      () => SharedPreferencesActiveWorkspaceStorage(t()),
    )
    ..registerLazySingleton<AuthenticationService>(
      () => SupabaseAuthenticationService(t<SupabaseClient>().auth),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        config: t(),
        authentication: t(),
        workspaceStorage: t(),
        savedReads: SavedReadInterceptor(
          t<ReadSyncCubit>(),
          hasSession: () => t<AuthenticationService>().currentSession != null,
        ),
      ),
      dispose: (client) => client.dio.close(force: true),
    )
    ..registerLazySingleton<Dio>(() => t<ApiClient>().dio)
    ..registerLazySingleton<AuthenticationRepository>(() => AuthenticationApiRepository(t()))
    ..registerLazySingleton<SessionCoordinator>(
      () => SessionCoordinator(t(), t(), t()),
      dispose: (c) => c.close(),
    );
}
