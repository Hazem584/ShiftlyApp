import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

class MockShiftRepository implements ShiftRepository {
  const MockShiftRepository();

  ShiftPage _empty(ShiftQuery query) => ShiftPage(
    data: const [],
    pagination: ApiPagination(
      page: query.page,
      limit: query.limit,
      total: 0,
      totalPages: 0,
    ),
  );

  @override
  Future<ShiftRecord> cancelShift(String workspaceId, String shiftId) =>
      throw UnsupportedError('No preview shift');
  @override
  Future<ShiftRecord> createShift(String workspaceId, CreateShiftInput input) =>
      throw UnsupportedError('No preview shift');
  @override
  Future<ShiftRecord> getMyShift(String shiftId) =>
      throw UnsupportedError('No preview shift');
  @override
  Future<ShiftRecord> getWorkspaceShift(String workspaceId, String shiftId) =>
      throw UnsupportedError('No preview shift');
  @override
  Future<ShiftPage> listMyShifts(String workspaceId, ShiftQuery query) async =>
      _empty(query);
  @override
  Future<ShiftPage> listWorkspaceShifts(
    String workspaceId,
    ShiftQuery query,
  ) async => _empty(query);
  @override
  Future<ShiftRecord> updateShift(
    String workspaceId,
    String shiftId,
    UpdateShiftInput input,
  ) => throw UnsupportedError('No preview shift');
}
