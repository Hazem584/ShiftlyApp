import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_state.dart';

abstract class NotificationsCubitBase extends Cubit<NotificationsState> {
  NotificationsCubitBase(this.repository) : super(const NotificationsState());

  final NotificationRepository repository;
  FeatureSessionScope? currentScope;
  var generation = 0, listRequestId = 0, countRequestId = 0;
  var listInFlight = false;

  FeatureSessionScope? get scope => currentScope;

  void finishMark(String id, {NotificationRecord? record, Failure? failure}) {
    final marking = {...state.markingIds}..remove(id);
    final updated = record == null
        ? state.notifications
        : state.notifications
              .map((item) => item.id == id ? record : item)
              .toList(growable: false);
    emit(
      state.copyWith(
        markingIds: marking,
        notifications: updated,
        failure: failure,
      ),
    );
  }

  void finishDelete(String id, {bool remove = false, Failure? failure}) {
    final deleting = {...state.deletingIds}..remove(id);
    final updated = remove
        ? state.notifications.where((i) => i.id != id).toList(growable: false)
        : state.notifications;
    emit(
      state.copyWith(
        deletingIds: deleting,
        notifications: updated,
        failure: failure,
      ),
    );
  }

  void validatePage(FeatureSessionScope scope, NotificationPage page) {
    if (page.data.any((item) => item.workspaceId != scope.workspaceId)) {
      throw const FormatException('Cross-workspace notification response');
    }
  }

  Failure toFailure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);

  bool isCurrentList(FeatureSessionScope scope, int gen, int reqId) =>
      isScopeCurrent(scope, gen) && listRequestId == reqId;

  bool isCurrentCount(FeatureSessionScope scope, int gen, int reqId) =>
      isScopeCurrent(scope, gen) && countRequestId == reqId;

  bool isScopeCurrent(FeatureSessionScope scope, int gen) =>
      !isClosed && currentScope == scope && generation == gen;
}
