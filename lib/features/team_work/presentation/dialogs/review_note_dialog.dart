import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

Future<String?> requestReviewNote(
  BuildContext context, {
  int minimumLength = 3,
}) async {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  final route = DialogRoute<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('Reason for declining')),
      content: Form(
        key: form,
        child: TextFormField(
          autofocus: true,
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          validator: (value) => (value?.trim().length ?? 0) < minimumLength
              ? context.tr('Please add a reason.')
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(context.tr('Decline')),
        ),
      ],
    ),
  );
  try {
    return await Navigator.of(context).push(route);
  } finally {
    await route.completed;
    controller.dispose();
  }
}
