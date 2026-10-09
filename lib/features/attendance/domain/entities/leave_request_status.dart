enum LeaveRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  unknown;

  static LeaveRequestStatus parse(Object? value) => switch (value) {
    'PENDING' => pending,
    'APPROVED' => approved,
    'REJECTED' => rejected,
    'CANCELLED' => cancelled,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    pending => 'PENDING',
    approved => 'APPROVED',
    rejected => 'REJECTED',
    cancelled => 'CANCELLED',
    unknown => null,
  };
}
