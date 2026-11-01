import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';

import '../design/access_theme.dart';

Future<T?> pushAccess<T>(BuildContext context, Widget screen) =>
    Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: (_) => AccessTheme(child: screen)));

void openAuthorizedWorkspace(BuildContext context) {
  final state = context.read<SessionCoordinator>().state;
  if (state.isAuthenticated) {
    context.go(
      state.status == SessionStatus.authenticatedManager
          ? '/dashboard'
          : '/employee',
    );
  }
}
