import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'access_icon.dart';
import 'access_theme.dart';

/// Scrolls body and actions together for keyboards, compact screens and large text.
class AccessPage extends StatelessWidget {
  const AccessPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.onBack,
    this.actions = const [],
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => AccessTheme(
    child: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (onBack != null) ...[
                                IconButton(
                                  tooltip: context.tr('Back'),
                                  onPressed: onBack,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 44,
                                  ),
                                  icon: const AccessIcon('back'),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  context.tr(title),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              ...actions,
                            ],
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              context.tr(subtitle!),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                          SizedBox(height: subtitle == null ? 38 : 48),
                          child,
                        ],
                      ),
                    ),
                  ),
                  if (footer != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: double.infinity,
                            child: footer,
                          ),
                        ),
                      ),
                    ),
                  if (footer == null)
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
