part of '../../leave_request_repository.dart';

class LeaveRequestQuery {
  const LeaveRequestQuery({
    this.page = 1,
    this.limit = 20,
    this.from,
    this.to,
    this.type,
    this.status,
    this.employeeMembershipId,
    this.search,
  });

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final LeaveRequestType? type;
  final LeaveRequestStatus? status;
  final String? employeeMembershipId;
  final String? search;

  Map<String, Object?> toQuery({required bool manager}) => {
    'page': page,
    'limit': limit,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
    if (type?.apiValue != null) 'type': type!.apiValue,
    if (status?.apiValue != null) 'status': status!.apiValue,
    if (manager && employeeMembershipId != null)
      'employeeMembershipId': employeeMembershipId,
    if (manager && search?.trim().isNotEmpty == true) 'search': search!.trim(),
  };

  LeaveRequestQuery copyWith({int? page}) => LeaveRequestQuery(
    page: page ?? this.page,
    limit: limit,
    from: from,
    to: to,
    type: type,
    status: status,
    employeeMembershipId: employeeMembershipId,
    search: search,
  );
}
