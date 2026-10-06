part of '../../shift_repository.dart';

class ShiftQuery {
  const ShiftQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.employeeMembershipId,
    this.status,
  });
  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String? employeeMembershipId;
  final ShiftStatus? status;

  Map<String, Object?> toQuery({bool includeEmployee = true}) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (includeEmployee && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (status?.apiValue != null) 'status': status!.apiValue,
  };

  ShiftQuery copyWith({int? page}) => ShiftQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    employeeMembershipId: employeeMembershipId,
    status: status,
  );
}
