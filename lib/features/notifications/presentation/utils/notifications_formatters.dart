import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/open_app_route.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/communication/presentation/communication_actions.dart';
import 'package:shiftly/features/communication/presentation/notification_unavailable_screen.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_destination.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_destination_verifier.dart';

abstract final class NotificationsScreenNotificationNavigator {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Future<void> open(
    BuildContext context,
    FeatureSessionScope? scope,
    NotificationRecord notification,
  ) async {
    if (scope == null || notification.workspaceId != scope.workspaceId) {
      return _unavailable(context);
    }
    final cubit = context.read<NotificationsCubit>();
    final dest = resolveNotificationDestination(scope, notification);
    if (cubit.scope != scope || dest == null || !_uuid.hasMatch(dest.id)) {
      return _unavailable(context);
    }
    try {
      final valid = await verifyNotificationDestinationExists(
        context,
        scope,
        dest,
      );
      if (!context.mounted || !valid || cubit.scope != scope) {
        if (context.mounted) _unavailable(context);
        return;
      }
      final router = GoRouter.of(context);
      if (cubit.scope == scope) openAppRoute(router, dest.location);
    } catch (_) {
      if (context.mounted) _unavailable(context);
    }
  }

  static void _unavailable(BuildContext context) => unawaited(
    openCommunicationPage(context, const NotificationUnavailableScreen()),
  );
}
