import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class EmployeeShellScreen extends StatelessWidget {
  const EmployeeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator>().state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shiftly'),
        actions: [
          IconButton(
            key: const Key('employee-logout'),
            onPressed: context.read<SessionCoordinator>().signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: 52),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Employee workspace',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  session.activeMembership?.workspace.name ?? '',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'Dashboard, shifts, and attendance data remain mocked until the next integration sprint.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
