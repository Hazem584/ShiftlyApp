import 'package:flutter/material.dart';

import 'package:shiftly/core/routing/app_routes.dart';

class RouteNotFoundScreen extends StatelessWidget {
  final String? routeName;

  const RouteNotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                "No route found",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (routeName != null && routeName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(routeName!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.root, (route) => false),
                child: Text("Go to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
