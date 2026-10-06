part of '../../leave_request_repository.dart';

class LeaveRequestPage {
  const LeaveRequestPage({required this.data, required this.pagination});
  final List<LeaveRequestRecord> data;
  final ApiPagination pagination;
}
