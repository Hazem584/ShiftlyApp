enum WorkspaceRole {
  manager,
  employee,
  unknown;

  static WorkspaceRole parse(Object? value) => switch (value) {
    'MANAGER' => manager,
    'EMPLOYEE' => employee,
    _ => unknown,
  };
}
