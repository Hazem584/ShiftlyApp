import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({
    required this.title,
    required this.children,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => CollaborationAppearance(
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(context.tr(title))),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 488),
              child: LayoutBuilder(
                builder: (context, viewport) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        children: children,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: viewport.maxHeight * .48,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          shrinkWrap: true,
                          primary: false,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
