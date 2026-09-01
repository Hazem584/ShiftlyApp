import 'package:flutter/material.dart';
import 'package:shiftly/core/routing/route_not_found_screen.dart';
import 'package:shiftly/features/home/home_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String root = '/';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());

      default:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => RouteNotFoundScreen(routeName: routeSettings.name),
        );
    }
  }
}
