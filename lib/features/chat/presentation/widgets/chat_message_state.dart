import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class ChatMessageState extends StatelessWidget {
  const ChatMessageState({super.key, required this.message, this.action});
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Icon(
                Icons.forum_outlined,
                color: AppColors.orange,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Workspace groups appear here once a manager creates one.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (action != null)
            TextButton(onPressed: action, child: Text(context.tr('Retry'))),
        ],
      ),
    ),
  );
}
