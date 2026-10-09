import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/chat/data/chat_member_loader.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';
import 'package:shiftly/features/chat/data/chat_media_validation.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_scope.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_cache.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_group_details_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/dialogs/shiftly_chat_dialog.dart';
import 'package:shiftly/features/chat/presentation/widgets/messages/shiftly_chat_message_list.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:url_launcher/url_launcher.dart';

part 'parts/chat_screen/chat_screen.dart';
part 'parts/chat_screen/pending_media_bubble.dart';

part 'parts/chat_screen/private_chat_view.dart';
part 'parts/chat_screen/private_chat_view_state.dart';
part 'parts/chat_screen/private_edit_chat_group_dialog.dart';
part 'parts/chat_screen/private_edit_chat_group_dialog_state.dart';
part 'parts/chat_screen/private_message_bubble.dart';
part 'parts/chat_screen/private_remote_image.dart';
part 'parts/chat_screen/private_remote_image_state.dart';
part 'parts/chat_screen/private_full_screen_image.dart';
part 'parts/chat_screen/private_voice_message.dart';
part 'parts/chat_screen/private_voice_message_state.dart';
part 'parts/chat_screen/private_location_card.dart';
part 'parts/chat_screen/private_members_sheet.dart';

String _nameInitials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
