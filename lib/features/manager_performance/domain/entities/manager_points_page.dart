import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';

class ManagerPointsPage {
  const ManagerPointsPage(this.records, {this.pagination});
  final List<ManagerPointsRecord> records;
  final ApiPagination? pagination;
}
