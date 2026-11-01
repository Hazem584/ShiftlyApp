import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

import '../design/access_theme.dart';

class AccessSessionLoading extends StatelessWidget {
  const AccessSessionLoading({super.key});
  @override
  Widget build(BuildContext context) => AccessTheme(
    child: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Align(
            alignment: const Alignment(0, -.18),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 72),
                  const SizedBox(height: 44),
                  Text(
                    context.tr('Getting your workspace ready'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 120,
                      height: 4,
                      child: LinearProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? .36
                            : null,
                        backgroundColor: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr('This may take a moment.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
