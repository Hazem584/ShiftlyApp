part of '../../attendance_repository.dart';

class AttendanceQuery {
  const AttendanceQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.employeeMembershipId,
    this.reviewStatus,
    this.shiftStatus,
  });
  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String? employeeMembershipId;
  final AttendanceReviewStatus? reviewStatus;
  final ShiftStatus? shiftStatus;

  Map<String, Object?> toQuery({
    bool includeEmployee = true,
    bool includeShiftStatus = true,
  }) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (includeEmployee && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (reviewStatus != null && reviewStatus != AttendanceReviewStatus.unknown)
      'reviewStatus': switch (reviewStatus!) {
        AttendanceReviewStatus.pending => 'PENDING',
        AttendanceReviewStatus.approved => 'APPROVED',
        AttendanceReviewStatus.rejected => 'REJECTED',
        AttendanceReviewStatus.unknown => null,
      },
    if (includeShiftStatus && shiftStatus?.apiValue != null)
      'shiftStatus': shiftStatus!.apiValue,
  };

  AttendanceQuery copyWith({int? page}) => AttendanceQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    employeeMembershipId: employeeMembershipId,
    reviewStatus: reviewStatus,
    shiftStatus: shiftStatus,
  );
}
