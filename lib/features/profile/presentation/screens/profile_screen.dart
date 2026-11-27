import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/confirm_action.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/communication/presentation/communication_page.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_menu_content.dart';

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
      if (_signingOut) return buildSigningOutPage(context);
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
        child: buildProfileMenuContent(context, p, _error),
      );
    },
  );
}
