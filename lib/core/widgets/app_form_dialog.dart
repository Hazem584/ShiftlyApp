import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

/// One dialog surface with a scrolling form and always-visible actions.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.icon = Icons.edit_outlined,
    this.busy = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget content;
  final List<Widget> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: math.max(
              0,
              media.size.height -
                  media.viewInsets.vertical -
                  media.viewPadding.vertical -
                  48,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.orangeSoft,
                            borderRadius: BorderRadius.circular(AppRadii.m),
                          ),
                          child: Icon(icon, color: AppColors.orange, size: 26),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr(title),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          context.tr(subtitle!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 20),
                      content,
                    ],
                  ),
                ),
              ),
              if (busy) const LinearProgressIndicator(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OverflowBar(
                  spacing: 12,
                  overflowSpacing: 8,
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
