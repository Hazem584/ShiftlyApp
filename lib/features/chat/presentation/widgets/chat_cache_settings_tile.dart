import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/manager/presentation/design/manager_theme_marker.dart';
import 'package:shiftly/features/manager/presentation/widgets/manager_confirmation_sheet.dart';

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
          context.tr('{value1} MB · active files are retained', {
            'value1': (((snapshot.data ?? 0) / 1000000).toStringAsFixed(1))
                .toString(),
          }),
        ),
        trailing: TextButton(
          onPressed: _busy
              ? null
              : () async {
                  if (Theme.of(context).extension<ManagerThemeMarker>() !=
                      null) {
                    final confirmed = await showManagerConfirmation(
                      context,
                      title: 'Clear cached media?',
                      description: context.tr(
                        'Remove downloaded chat media from this device. Active files are retained.',
                      ),
                      action: 'Clear cache',
                      confirmKey: const Key('confirm-clear-chat-cache'),
                    );
                    if (!confirmed || !mounted) return;
                  }
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
