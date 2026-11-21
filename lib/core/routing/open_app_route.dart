import 'package:go_router/go_router.dart';

void openAppRoute(GoRouter router, String location) {
  final current = router.routerDelegate.currentConfiguration.matches;
  final target = router.configuration.findMatch(Uri.parse(location)).matches;
  // A root overlay above an existing shell cannot push a second copy of it.
  // Switch branches in this case; the shell's back boundary returns home.
  final shellBelowOverlay =
      current.isNotEmpty &&
      current.last is! ShellRouteMatch &&
      current.any((match) => match is ShellRouteMatch);
  final targetsShell = target.any(
    (match) =>
        match is ShellRouteMatch ||
        (match.route is GoRoute && (match.route as GoRoute).redirect != null),
  );
  if (shellBelowOverlay && targetsShell) {
    router.go(location);
  } else {
    router.push<void>(location);
  }
}
