import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';

class ScheduleExceptionPage {
  const ScheduleExceptionPage(this.data, this.pagination);
  final List<ScheduleException> data;
  final ApiPagination pagination;
}

abstract interface class ScheduleExceptionRepository {
  Future<ScheduleExceptionPage> list(
    String workspaceId, {
    String? employeeMembershipId,
    int page = 1,
  });
  Future<ScheduleException> create(
    String workspaceId, {
    required String clientExceptionId,
    required String kind,
    required String operationalDate,
    required String reason,
    String? employeeMembershipId,
    String? shiftTemplateId,
  });
  Future<ScheduleException> cancel(
    String workspaceId,
    String id,
    String reason,
  );
}
