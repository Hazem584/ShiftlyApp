import 'package:shiftly/core/network/api_model_parser.dart';

import 'manager_points_record.dart';

class ManagerPointsPage {
  const ManagerPointsPage(this.records, {this.pagination});
  final List<ManagerPointsRecord> records;
  final ApiPagination? pagination;
}
