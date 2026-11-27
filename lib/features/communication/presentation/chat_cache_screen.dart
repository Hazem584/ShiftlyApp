import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/communication/presentation/chat_cache_content.dart';

import 'communication_page.dart';

class ChatCacheScreen extends StatefulWidget {
  const ChatCacheScreen({super.key});
  @override
  State<ChatCacheScreen> createState() => _ChatCacheScreenState();
}

class _ChatCacheScreenState extends State<ChatCacheScreen> {
  bool _busy = false;
  String? _error;
  late Future<int> _size = _measure();
  late final FeatureSessionScope? _scope = context
      .read<ChatGroupsCubit?>()
      ?.scope;

  Future<int> _measure() async =>
      await context.read<ChatGroupsCubit?>()?.mediaCache?.size() ?? 0;

  Future<void> _clear() async {
    if (_busy) return;
    final confirmed = await confirmAction(
      context,
      title: 'Clear cached media?',
      message: 'Remove downloaded chat media from this device. Open an attachment again to download it when online.',
      action: 'Clear cache',
      actionKey: 'confirm-clear-chat-cache',
    );
    if (!mounted ||
        !confirmed ||
        context.read<ChatGroupsCubit?>()?.scope != _scope) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<ChatGroupsCubit?>()?.mediaCache?.clear();
      if (mounted) setState(() => _size = _measure());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not clear the cache. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Chat cache',
    footer: FilledButton(
      key: const Key('clear-chat-cache'),
      onPressed: _busy ? null : _clear,
      child: Text(context.tr(_busy ? 'Clearing…' : 'Clear chat cache')),
    ),
    child: buildChatCacheContent(context, sizeFuture: _size, error: _error),
  );
}
