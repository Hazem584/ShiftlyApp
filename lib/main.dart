import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/bootstrap/app_bootstrap.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/config/configuration_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final dependencies = await AppBootstrap.initialize();
    runApp(
      ShiftlyApp(
        sessionCoordinator: dependencies.sessionCoordinator,
        profileRepository: dependencies.profileRepository,
        employeeRepository: dependencies.employeeRepository,
        invitationRepository: dependencies.invitationRepository,
        workspaceRepository: dependencies.workspaceRepository,
        shiftRepository: dependencies.shiftRepository,
        attendanceRepository: dependencies.attendanceRepository,
        leaveRequestRepository: dependencies.leaveRequestRepository,
      ),
    );
    unawaited(dependencies.sessionCoordinator.initialize());
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
