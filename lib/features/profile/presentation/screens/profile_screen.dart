import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_cache_settings_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_header.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_information_section.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';

part 'parts/profile_screen/private_profile_screen_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.onLogout, super.key});

  final Future<void> Function()? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
