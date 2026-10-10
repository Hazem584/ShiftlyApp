import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class ChatCacheSettingsTile extends StatefulWidget {
  const ChatCacheSettingsTile({super.key});
  @override
  State<ChatCacheSettingsTile> createState() => _ChatCacheSettingsTileState();
}

class _ChatCacheSettingsTileState extends State<ChatCacheSettingsTile> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final cache = context.read<ChatGroupsCubit?>()?.mediaCache;
    if (cache == null) return const SizedBox.shrink();
    return FutureBuilder<int>(
      future: cache.size(),
      builder: (_, snapshot) => ListTile(
        leading: const Icon(Icons.storage_outlined),
        title: Text(context.tr('Chat media cache')),
        subtitle: Text(
          context.tr('{value1} MiB · active files are retained', {
            'value1': (((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(
              1,
            )).toString(),
          }),
        ),
        trailing: TextButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await cache.clear();
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text(context.tr('Clear')),
        ),
      ),
    );
  }
}
