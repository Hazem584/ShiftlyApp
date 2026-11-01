import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

/// The mounted dialog owns its controller until its route transition finishes.
class ManagerReasonDialog extends StatefulWidget {
  const ManagerReasonDialog({
    required this.title,
    required this.confirm,
    this.minimumLength = 3,
    super.key,
  });
  final String title, confirm;
  final int minimumLength;
  @override
  State<ManagerReasonDialog> createState() => _ManagerReasonDialogState();
}

class _ManagerReasonDialogState extends State<ManagerReasonDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(widget.title)),
    scrollable: true,
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: TextFormField(
          key: const Key('manager-review-reason'),
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(labelText: context.tr('Reason')),
          validator: (v) => (v?.trim().length ?? 0) < widget.minimumLength
              ? context.tr('Please add a reason.')
              : null,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: Text(context.tr(widget.confirm)),
      ),
    ],
  );
}
