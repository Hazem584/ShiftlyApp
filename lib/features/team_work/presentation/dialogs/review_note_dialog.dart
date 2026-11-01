import 'package:flutter/material.dart';
import 'package:shiftly/features/manager/presentation/widgets/manager_reason_dialog.dart';

Future<String?> requestReviewNote(
  BuildContext context, {
  int minimumLength = 3,
}) => showDialog<String>(
  context: context,
  builder: (_) => ManagerReasonDialog(
    title: 'Reason for declining',
    confirm: 'Decline',
    minimumLength: minimumLength,
  ),
);
