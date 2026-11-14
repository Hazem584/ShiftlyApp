import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';

class ManagerFormPage extends StatelessWidget {
  const ManagerFormPage({
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.header,
    this.onBack,
    this.busy = false,
    super.key,
  });
  final Widget? header;
  final VoidCallback? onBack;
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  final bool busy;
  @override
  Widget build(BuildContext context) => CollaborationSessionBoundary(
    child: PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          title: header ?? Text(context.tr(title)),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (subtitle != null) ...[
                            Text(
                              context.tr(subtitle!),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                          ],
                          content,
                        ],
                      ),
                    ),
                  ),
                  if (busy) const AppContentLoading(rows: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: actions.reversed.toList(),
                    ),
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
