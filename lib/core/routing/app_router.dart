import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_router_redirect.dart';
import 'package:shiftly/core/routing/app_session_routes.dart';
import 'package:shiftly/core/routing/app_shell_routes.dart';
import 'package:shiftly/core/routing/app_standalone_routes.dart';
import 'package:shiftly/core/routing/route_not_found_screen.dart';
import 'package:shiftly/core/routing/session_route_intent.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';

GoRouter createAppRouter({
  SessionCoordinator? sessionCoordinator,
  OnboardingCubit? onboarding,
  Listenable? refreshListenable,
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final routeIntent = SessionRouteIntent();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: sessionCoordinator == null ? '/dashboard' : '/session',
    refreshListenable: refreshListenable,
    redirect: sessionCoordinator == null
        ? null
        : (context, state) {
            routeIntent.remember(state.uri, sessionCoordinator.state.status);
            final redirect = resolveAppRedirect(
              sessionCoordinator,
              state,
              onboarding,
            );
            return redirect == null
                ? null
                : routeIntent.takeFor(sessionCoordinator.state.status) ??
                      redirect;
          },
    errorBuilder: (context, state) =>
        RouteNotFoundScreen(routeName: state.uri.path),
    routes: [
      ...buildStandaloneAppRoutes(sessionCoordinator),
      ...buildSessionAppRoutes(),
      buildEmployeeShellRoute(),
      buildManagerShellRoute(rootNavigatorKey, sessionCoordinator),
    ],
  );
}
