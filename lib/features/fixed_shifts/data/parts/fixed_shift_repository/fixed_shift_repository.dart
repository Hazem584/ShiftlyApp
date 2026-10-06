part of '../../fixed_shift_repository.dart';

abstract interface class FixedShiftRepository {
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  });
  Future<ShiftTemplate> getTemplate(String workspaceId, String templateId);
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  );
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  );
  Future<ShiftTemplate> archiveTemplate(String workspaceId, String templateId);
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId,
  );
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  });
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  });
  Future<TemplateEligibility> getEligibility(String workspaceId);
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId);
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
  });
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId);
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  });
  Future<void> savePendingClockIn(PendingClockIn value);
  Future<void> clearPendingClockIn(PendingClockIn value);
}
