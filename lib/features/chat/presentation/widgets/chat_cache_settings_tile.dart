import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

part 'private_chat_cache_settings_tile_state.dart';

class ChatCacheSettingsTile extends StatefulWidget {
  const ChatCacheSettingsTile({super.key});
  @override
  State<ChatCacheSettingsTile> createState() => _ChatCacheSettingsTileState();
}
