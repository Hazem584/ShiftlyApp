import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/config/configuration_error_app.dart';
import 'package:shiftly/core/di/dependency_registration.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await DependencyRegistration.configureProduction();
    runApp(ShiftlyApp(locator: getIt));
    unawaited(getIt<SessionCoordinator>().initialize());
  } on AppConfigException catch (error) {
    runApp(ConfigurationErrorApp(message: error.message));
  } catch (_) {
    runApp(
      const ConfigurationErrorApp(
        message: 'Application services could not be initialized. Try again.',
      ),
    );
  }
}
