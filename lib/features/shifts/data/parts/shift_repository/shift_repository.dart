part of '../../shift_repository.dart';

abstract interface class ShiftRepository {
  Future<ShiftPage> listWorkspaceShifts(String workspaceId, ShiftQuery query);
  Future<ShiftRecord> getWorkspaceShift(String workspaceId, String shiftId);
  Future<ShiftRecord> createShift(String workspaceId, CreateShiftInput input);
  Future<ShiftRecord> updateShift(
    String workspaceId,
    String shiftId,
    UpdateShiftInput input,
  );
  Future<ShiftRecord> cancelShift(String workspaceId, String shiftId);
  Future<ShiftPage> listMyShifts(String workspaceId, ShiftQuery query);
  Future<ShiftRecord> getMyShift(String shiftId);
}
