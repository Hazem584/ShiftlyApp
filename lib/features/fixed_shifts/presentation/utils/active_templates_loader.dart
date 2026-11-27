import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

Future<List<ShiftTemplate>> loadActiveWorkspaceTemplates(
  FixedShiftRepository repository,
  String workspaceId, {
  required bool Function() isMounted,
}) async {
  final result = <ShiftTemplate>[];
  var page = 1;
  while (true) {
    final value = await repository.listTemplates(workspaceId, page: page);
    if (!isMounted()) return result;
    if (value.data.any((v) => v.workspaceId != workspaceId)) {
      throw const FormatException('Invalid template scope');
    }
    result.addAll(value.data.where((v) => v.active));
    if (page >= value.pagination.totalPages) break;
    page++;
  }
  return result;
}
