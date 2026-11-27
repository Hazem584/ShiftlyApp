import 'package:flutter/material.dart';

class PlatformRetryButton extends StatelessWidget {
  const PlatformRetryButton({
    required this.arabic,
    required this.checking,
    required this.onRefresh,
    super.key,
  });
  final bool arabic, checking;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: checking ? null : onRefresh,
    icon: checking
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.refresh),
    label: Text(arabic ? 'إعادة المحاولة' : 'Try again'),
  );
}
