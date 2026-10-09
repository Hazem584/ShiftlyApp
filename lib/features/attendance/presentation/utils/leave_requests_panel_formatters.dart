import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

LeaveRequestQuery leaveRequestsPanelQuery(
  LeaveRequestQuery current, {
  LeaveRequestStatus? status,
  LeaveRequestType? type,
  bool replaceStatus = false,
  bool replaceType = false,
}) => LeaveRequestQuery(
  limit: current.limit,
  from: current.from,
  to: current.to,
  status: replaceStatus ? status : current.status,
  type: replaceType ? type : current.type,
  employeeMembershipId: current.employeeMembershipId,
  search: current.search,
);
