import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';

import 'communication_appearance.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.actions,
    this.onBack,
    this.guardSession = true,
    this.localizeTitle = true,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool guardSession;
  final bool localizeTitle;
  @override
  Widget build(BuildContext context) {
    final page = CommunicationAppearance(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleTextStyle: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            title: Text(
              localizeTitle ? context.tr(title) : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: BackButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            actions: actions,
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        child: Text(
                          context.tr(subtitle!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    Expanded(child: child),
                    if (footer != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return guardSession ? CollaborationSessionBoundary(child: page) : page;
  }
}
