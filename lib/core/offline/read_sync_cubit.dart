import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_state.dart';

import 'read_sync_state.dart';
import 'saved_read_store.dart';

class ReadSyncCubit extends Cubit<ReadSyncState> {
  ReadSyncCubit(this.store) : super(const ReadSyncState({}));
  final SavedReadStore store;
  String? owner;
  String? workspaceId;
  int generation = 0;

  void bind(SessionState session) {
    if (session.isAuthenticated) {
      final membership = session.activeMembership!;
      final next =
          '${session.currentUser!.id}|${membership.workspace.id}|${membership.id}|${membership.role.name}';
      if (owner == next) return;
      owner = next;
      workspaceId = membership.workspace.id;
      generation++;
      emit(const ReadSyncState({}));
    } else {
      final previous = owner;
      owner = null;
      workspaceId = null;
      generation++;
      emit(const ReadSyncState({}));
      if (previous != null &&
          (session.status == SessionStatus.unauthenticated ||
              session.status == SessionStatus.sessionExpired)) {
        unawaited(store.clearUser(previous.split('|').first));
      }
    }
  }

  bool current(String identity, int epoch) =>
      !isClosed && owner == identity && generation == epoch;

  void begin(ReadCategory category) {
    final before = state.statuses[category] ?? const ReadSyncStatus();
    _set(
      category,
      ReadSyncStatus(
        pending: before.pending + 1,
        updatedAt: before.updatedAt,
        usingSaved: before.pending > 0 && before.usingSaved,
        failed: before.pending > 0 && before.failed,
      ),
    );
  }

  void finish(
    ReadCategory category, {
    DateTime? updatedAt,
    bool saved = false,
    bool failed = false,
  }) {
    final before = state.statuses[category] ?? const ReadSyncStatus();
    // Keep the oldest saved timestamp when a screen combines several reads.
    final timestamp = before.usingSaved && before.updatedAt != null
        ? saved && updatedAt != null && updatedAt.isBefore(before.updatedAt!)
              ? updatedAt
              : before.updatedAt
        : updatedAt ?? before.updatedAt;
    _set(
      category,
      ReadSyncStatus(
        pending: (before.pending - 1).clamp(0, 1000),
        updatedAt: timestamp,
        usingSaved: before.usingSaved || saved,
        failed: before.failed || failed,
      ),
    );
  }

  void _set(ReadCategory category, ReadSyncStatus status) =>
      emit(ReadSyncState({...state.statuses, category: status}));
}
