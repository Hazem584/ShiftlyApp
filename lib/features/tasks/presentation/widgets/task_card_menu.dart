import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

void showTaskCardMenu(
  BuildContext context, {
  required VoidCallback onOpen,
  required VoidCallback onDelete,
}) {
  final colors = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(context.tr('Task details')),
            onTap: () {
              Navigator.pop(c);
              onOpen();
            },
          ),
          ListTile(
            title: Text(context.tr('Delete task')),
            leading: Icon(Icons.delete_outline, color: colors.error),
            onTap: () {
              Navigator.pop(c);
              onDelete();
            },
          ),
        ],
      ),
    ),
  );
}
