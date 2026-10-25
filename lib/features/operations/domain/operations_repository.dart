typedef OperationMap = Map<String, Object?>;

abstract interface class OperationsRepository {
  Future<List<OperationMap>> profiles(String workspaceId);
  Future<void> saveProfile(
    String workspaceId,
    String memberId,
    OperationMap value,
  );
  Future<List<OperationMap>> proposals(String workspaceId);
  Future<OperationMap> generate(String workspaceId, OperationMap value);
  Future<OperationMap> approve(
    String workspaceId,
    String id,
    OperationMap value,
  );
  Future<List<OperationMap>> occurrences(String workspaceId, String from);
  Future<OperationMap> handovers(String workspaceId, int page);
  Future<OperationMap> handover(String workspaceId, String id);
  Future<OperationMap> createHandover(String workspaceId, OperationMap value);
  Future<void> receive(String workspaceId, String id, int revision);
  Future<void> updateItem(
    String workspaceId,
    String id,
    String item,
    OperationMap value,
  );
  Future<OperationMap> forward(
    String workspaceId,
    String id,
    OperationMap value,
  );
}
