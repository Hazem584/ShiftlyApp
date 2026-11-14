import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/preview_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class ManagerTemplateRepository extends PreviewFixedShiftRepository {
  final items = <ShiftTemplate>[
    for (final entry in [
      ('morning', 'Morning operations', true),
      ('evening', 'Evening support', true),
      ('archived', 'Old inventory shift', false),
    ])
      ShiftTemplate(
        id: entry.$1,
        workspaceId: 'preview-workspace',
        name: entry.$2,
        color: '#4338CA',
        startMinute: 480,
        endMinute: 960,
        graceMinutes: 10,
        allowedEarlyCheckInMinutes: 15,
        allowedLateCheckInMinutes: 60,
        minimumWorkMinutes: 240,
        active: entry.$3,
        overnight: false,
        createdAt: DateTime.utc(2026, 11),
        updatedAt: DateTime.utc(2026, 11),
      ),
  ];
  @override
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  }) async {
    final values = items.where((t) => includeArchived || t.active).toList();
    return ShiftTemplatePage(
      data: values,
      pagination: ApiPagination(
        page: 1,
        limit: 100,
        total: values.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  ) async {
    final template = ShiftTemplate(
      id: 'created',
      workspaceId: workspaceId,
      name: input.name,
      description: input.description,
      color: input.color,
      startMinute: input.startMinute,
      endMinute: input.endMinute,
      graceMinutes: input.graceMinutes,
      allowedEarlyCheckInMinutes: input.allowedEarlyCheckInMinutes,
      allowedLateCheckInMinutes: input.allowedLateCheckInMinutes,
      minimumWorkMinutes: input.minimumWorkMinutes,
      breakMinutes: input.breakMinutes,
      breakStartMinute: input.breakStartMinute,
      active: true,
      overnight: input.endMinute <= input.startMinute,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    items.add(template);
    return template;
  }
}
