import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/communication/presentation/devices_storage_screen.dart';
import 'package:shiftly/features/communication/presentation/preferences_screen.dart';
import 'package:shiftly/features/communication/presentation/profile_edit_screen.dart';
import 'package:shiftly/features/communication/presentation/service_information_screen.dart';
import 'package:shiftly/features/communication/presentation/workspace_settings_screen.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.onLogout, super.key});
  final Future<void> Function()? onLogout;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;
  String? _error;
  Future<void> _logout() async {
    if (_signingOut || widget.onLogout == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Sign out of Shiftly?',
      message: 'You’ll need to sign in again to access your workspaces. Your account and team records stay saved.',
      action: 'Sign out',
      actionKey: 'confirm-sign-out',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onLogout!();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not sign out. Try again.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileCubit, ProfileState>(
    builder: (context, state) {
      if (_signingOut) {
        return CommunicationPage(
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
      }
      if (state is ProfileLoading) {
        return const CommunicationPage(
          title: 'Profile',
          child: AppContentLoading(),
        );
      }
      if (state is ProfileError) {
        return CommunicationPage(
          title: 'Profile',
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            message: state.message,
            action: FilledButton(
              onPressed: context.read<ProfileCubit>().load,
              child: Text(context.tr('Retry')),
            ),
          ),
        );
      }
      if (state is! ProfileLoaded) return const SizedBox.shrink();
      final p = state.profile;
      return CommunicationPage(
        title: p.displayName,
        guardSession: false,
        localizeTitle: false,
        subtitle: '${p.role} · ${p.workplace}',
        footer: widget.onLogout == null
            ? null
            : TextButton(
                key: const Key('manager-logout'),
                onPressed: _logout,
                child: Text(
                  context.tr('Sign out'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
        child: ListView(
          key: const Key('profile-content'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            for (final item in <(String, String, String, IconData, Widget)>[
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
            ]) ...[
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
            if (_error != null)
              Text(
                context.tr(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    },
  );
}
