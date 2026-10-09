enum DashboardAttendanceStatus {
  clockedIn,
  completed,
  unknown;

  static DashboardAttendanceStatus parse(Object? value) => switch (value) {
    'CLOCKED_IN' => clockedIn,
    'COMPLETED' => completed,
    _ => unknown,
  };
}
