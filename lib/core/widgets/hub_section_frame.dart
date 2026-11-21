import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class HubSectionFrame extends StatelessWidget {
  const HubSectionFrame({
    required this.title,
    required this.fallback,
    required this.child,
    super.key,
  });
  final String title;
  final String fallback;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go(fallback);
              }
            },
            icon: const BackButtonIcon(),
            label: Text(context.tr(title)),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}
