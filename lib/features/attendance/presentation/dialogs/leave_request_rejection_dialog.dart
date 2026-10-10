import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class LeaveRequestRejectionDialog extends StatefulWidget {
  const LeaveRequestRejectionDialog({super.key, required this.employeeName});
  final String employeeName;

  @override
  State<LeaveRequestRejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<LeaveRequestRejectionDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Reject request?')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Explain why {value1}’s request is being rejected.', {
              'value1': (widget.employeeName).toString(),
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('rejection-reason'),
            controller: _controller,
            maxLength: 1000,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.tr('Rejection reason'),
              errorText: _error == null ? null : context.tr(_error!),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        key: const Key('confirm-reject'),
        onPressed: () {
          final reason = _controller.text.trim();
          if (reason.isEmpty) {
            setState(() => _error = 'A reason is required');
            return;
          }
          Navigator.pop(context, reason);
        },
        child: Text(context.tr('Reject')),
      ),
    ],
  );
}
