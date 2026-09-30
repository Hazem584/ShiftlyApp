import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_header.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_information_section.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({this.onLogout, super.key});

  final Future<void> Function()? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _switchingWorkspace = false;

  Future<void> _showWorkspaceChooser() async {
    if (_switchingWorkspace) return;
    await showWorkspaceSwitcher(
      context,
      onSwitchingChanged: (switching) {
        if (mounted) setState(() => _switchingWorkspace = switching);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileError(:final message) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            message: message,
            action: FilledButton(
              onPressed: context.read<ProfileCubit>().load,
              child: const Text('Retry'),
            ),
          ),
          ProfileLoaded(:final profile, :final action) =>
            _editing
                ? ProfileEditForm(
                    key: const Key('profile-editor'),
                    profile: profile,
                    action: action,
                    onCancel: () => setState(() => _editing = false),
                    onSaved: () => setState(() => _editing = false),
                  )
                : ListView(
                    key: const Key('profile-content'),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                    children: [
                      ScreenHeader(
                        title: 'Manager Profile',
                        subtitle: 'Your personal and workplace information',
                        action: FilledButton.icon(
                          key: const Key('edit-profile'),
                          onPressed: () => setState(() => _editing = true),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(82, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      ProfileHeader(profile: profile),
                      const SizedBox(height: AppSpacing.m),
                      ProfileInformationSection(profile: profile),
                      if (widget.onLogout != null) ...[
                        const SizedBox(height: AppSpacing.l),
                        OutlinedButton.icon(
                          key: const Key('switch-workspace'),
                          onPressed: _switchingWorkspace
                              ? null
                              : _showWorkspaceChooser,
                          icon: const Icon(Icons.business_outlined),
                          label: const Text('Switch workspace'),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        OutlinedButton.icon(
                          key: const Key('manager-logout'),
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
        },
      ),
    ),
  );
}
