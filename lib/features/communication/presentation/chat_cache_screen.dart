import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import 'communication_page.dart';

class ChatCacheScreen extends StatefulWidget {
  const ChatCacheScreen({super.key});
  @override
  State<ChatCacheScreen> createState() => _ChatCacheScreenState();
}

class _ChatCacheScreenState extends State<ChatCacheScreen> {
  bool _busy = false;
  String? _error;
  late Future<int> _size;
  late final FeatureSessionScope? _scope;
  @override
  void initState() {
    super.initState();
    _scope = context.read<ChatGroupsCubit?>()?.scope;
    _size = _measure();
  }

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
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        FutureBuilder<int>(
          future: _size,
          builder: (context, snapshot) => Text(
            snapshot.hasError
                ? context.tr('Cache size unavailable')
                : context.tr('{size} MB on this device', {
                    'size': snapshot.hasData
                        ? (snapshot.data! / 1000000).toStringAsFixed(1)
                        : '—',
                  }),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 28),
        for (final item in const [
          (Icons.image_outlined, 'Images', 'Downloaded chat images'),
          (Icons.description_outlined, 'Documents', 'Saved chat attachments'),
          (Icons.graphic_eq, 'Audio', 'Downloaded voice messages'),
        ]) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(item.$1),
              title: Text(context.tr(item.$2)),
              subtitle: Text(context.tr(item.$3)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Clear cached media to free space. Active files are retained; messages remain in your groups.',
          ),
        ),
        if (_error != null)
          Text(
            context.tr(_error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );
}
