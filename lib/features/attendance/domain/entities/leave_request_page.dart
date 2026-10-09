import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/entities/leave_request_record.dart';

class LeaveRequestPage {
  const LeaveRequestPage({required this.data, required this.pagination});
  final List<LeaveRequestRecord> data;
  final ApiPagination pagination;
}
