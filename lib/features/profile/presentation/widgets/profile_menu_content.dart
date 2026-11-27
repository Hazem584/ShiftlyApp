import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/communication/presentation/devices_storage_screen.dart';
import 'package:shiftly/features/communication/presentation/preferences_screen.dart';
import 'package:shiftly/features/communication/presentation/profile_edit_screen.dart';
import 'package:shiftly/features/communication/presentation/service_information_screen.dart';
import 'package:shiftly/features/communication/presentation/workspace_settings_screen.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

Widget buildSigningOutPage(BuildContext context) => CommunicationPage(
  title: 'Signing out',
  guardSession: false,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const AppContentLoading(rows: 1),
      Text(
        context.tr('Signing you out…'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Text(context.tr('Finishing your session on this device.')),
    ],
  ),
);

Widget buildProfileMenuContent(
  BuildContext context,
  ManagerProfile p,
  String? error,
) {
  final items = <(String, String, String, IconData, Widget)>[
    (
      'edit-profile',
      'Personal information',
      'Name, phone and profile photo',
      Icons.person_outline,
      ProfileEditScreen(cubit: context.read<ProfileCubit>()),
    ),
    (
      'profile-preferences',
      'Preferences',
      'Language · Appearance',
      Icons.tune,
      const PreferencesScreen(),
    ),
    (
      'profile-workspace',
      'Workspace',
      '${p.workplace} · ${context.tr('Switch workspace')}',
      Icons.business_outlined,
      const WorkspaceSettingsScreen(),
    ),
    (
      'profile-devices-storage',
      'Devices and storage',
      'Active sessions · Chat cache',
      Icons.devices_outlined,
      const DevicesStorageScreen(),
    ),
    (
      'profile-support-service',
      'Support and service',
      'Help · App information',
      Icons.support_agent_outlined,
      const ServiceInformationScreen(),
    ),
  ];
  return ListView(
    key: const Key('profile-content'),
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    children: [
      for (final item in items) ...[
        Card(
          child: ListTile(
            key: Key(item.$1),
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              item.$4,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            title: Text(
              context.tr(item.$2),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(context.tr(item.$3)),
            onTap: () => openCommunicationPage(context, item.$5),
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (error != null)
        Text(
          context.tr(error),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
