import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';

/// Empty adapter used only by unauthenticated widget previews and tests.
class PreviewFixedShiftRepository implements FixedShiftRepository {
  const PreviewFixedShiftRepository();

  ApiPagination get _empty =>
      const ApiPagination(page: 1, limit: 100, total: 0, totalPages: 0);
  Never _unsupported() =>
      throw UnsupportedError('Preview mutation unavailable');

  @override
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  }) async => ShiftTemplatePage(data: const [], pagination: _empty);
  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) async => ShiftTemplatePage(data: const [], pagination: _empty);
  @override
  Future<TemplateEligibility> getEligibility(String workspaceId) async =>
      TemplateEligibility(
        workspaceId: workspaceId,
        timezone: 'Etc/UTC',
        evaluatedAt: DateTime.now().toUtc(),
        recommended: null,
        eligibleTemplates: const [],
      );
  @override
  Future<WorkPatternHistory> getWorkPatterns(
    String workspaceId,
    String membershipId,
  ) async => const WorkPatternHistory(current: null, history: []);
  @override
  Future<FlexibleAttendance?> getCurrentAttendance(String workspaceId) async =>
      null;
  @override
  Future<PendingClockIn?> loadPendingClockIn() async => null;
  @override
  Future<void> clearPendingClockIn() async {}
  @override
  Future<void> savePendingClockIn(PendingClockIn value) async {}
  @override
  Future<ShiftTemplate> getTemplate(
    String workspaceId,
    String templateId,
  ) async => _unsupported();
  @override
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  ) async => _unsupported();
  @override
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  ) async => _unsupported();
  @override
  Future<ShiftTemplate> archiveTemplate(
    String workspaceId,
    String templateId,
  ) async => _unsupported();
  @override
  Future<WorkPattern> replaceWorkPattern(
    String workspaceId,
    String membershipId, {
    required List<int> expectedWeekdays,
    required String effectiveFrom,
  }) async => _unsupported();
  @override
  Future<FlexibleAttendance> flexibleClockIn({
    required String workspaceId,
    required String shiftTemplateId,
    required String clientAttendanceId,
  }) async => _unsupported();
  @override
  Future<FlexibleAttendance> flexibleClockOut(String attendanceId) async =>
      _unsupported();
}
