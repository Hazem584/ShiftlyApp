import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';

class WorkspaceLocalCleanup {
  WorkspaceLocalCleanup({
    required this.session,
    required this.breaks,
    required this.reads,
    this.chat,
  });
  final SessionCoordinator? session;
  final ShiftBreakController breaks;
  final SavedReadStore reads;
  final ChatCacheDatabase? chat;
  Future<void> remove(String workspaceId, String userId) async {
    if (session?.state.currentUser?.id != userId) return;
    if (session?.state.activeMembership?.workspace.id == workspaceId) {
      await breaks.finish();
    }
    await session?.workspaceLeft(workspaceId, userId);
    await reads.clearWorkspace(userId, workspaceId);
    await chat?.purgeWorkspace(userId, workspaceId);
  }
}
