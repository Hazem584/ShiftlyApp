import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class SessionRouterRefresh extends ChangeNotifier {
  SessionRouterRefresh(
    SessionCoordinator coordinator,
    OnboardingCubit onboarding,
  ) {
    if (coordinator.state.isAuthenticated) {
      onboarding.bypassForValidatedSession();
    }
    _subscription = coordinator.stream.listen((state) {
      if (state.isAuthenticated) {
        onboarding.bypassForValidatedSession();
      }
      notifyListeners();
    });
    _onboardingSubscription = onboarding.stream.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<Object?> _subscription;
  late final StreamSubscription<Object?> _onboardingSubscription;

  @override
  void dispose() {
    _subscription.cancel();
    _onboardingSubscription.cancel();
    super.dispose();
  }
}
