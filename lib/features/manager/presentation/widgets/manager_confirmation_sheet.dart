import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

Future<bool> showManagerConfirmation(
  BuildContext context, {
  required String title,
  required String description,
  required String action,
  required Key confirmKey,
}) async {
  final session = context.read<SessionCoordinator?>();
  final owner = (
    session?.state.currentUser?.id,
    session?.state.activeMembership?.id,
  );
  final confirmed =
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(title),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: confirmKey,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.tr(action)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.tr('Cancel')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) ??
      false;
  return confirmed &&
      context.mounted &&
      owner ==
          (session?.state.currentUser?.id, session?.state.activeMembership?.id);
}
