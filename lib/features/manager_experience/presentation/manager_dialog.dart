import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/core/widgets/manager_form_page.dart';

class ManagerDialog extends StatelessWidget {
  const ManagerDialog({
    this.title,
    this.content,
    this.actions,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.contentPadding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
    this.actionsPadding = EdgeInsets.zero,
    this.scrollable = false,
    this.shape,
    this.onBack,
    super.key,
  });
  final Widget? title, content;
  final List<Widget>? actions;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry contentPadding, actionsPadding;
  final bool scrollable;
  final ShapeBorder? shape;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => ManagerDesign.applies(context)
      ? ManagerFormPage(
          title: '',
          header: title,
          onBack: onBack,
          content: content ?? const SizedBox.shrink(),
          actions: actions ?? const [],
        )
      : AlertDialog(
          title: title,
          content: content,
          actions: actions,
          insetPadding: insetPadding,
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          scrollable: scrollable,
          shape: shape,
        );
}
