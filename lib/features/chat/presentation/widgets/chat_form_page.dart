import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';

class ChatFormPage extends StatelessWidget {
  const ChatFormPage({
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.icon,
    this.busy = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool busy;
  final Widget content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    return CollaborationSessionBoundary(
      child: CollaborationAppearance(
        child: PopScope(
          canPop: !busy,
          child: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: Text(title)),
                body: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                24,
                                16,
                              ),
                              child: Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: content,
                            ),
                          ),
                          if (actions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: actions,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
