part of '../../leave_request_card.dart';

class _RejectionDialogState extends State<_RejectionDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reject request?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explain why ${widget.employeeName}’s request is being rejected.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('rejection-reason'),
            controller: _controller,
            maxLength: 1000,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Rejection reason',
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
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
        child: const Text('Reject'),
      ),
    ],
  );
}
