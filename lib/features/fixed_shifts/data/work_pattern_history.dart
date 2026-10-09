import 'package:shiftly/core/network/api_model_parser.dart';

import 'fixed_shift_repository.dart';

class WorkPatternHistory {
  const WorkPatternHistory({
    required this.current,
    required this.history,
    this.pagination,
  });
  final ApiPagination? pagination;
  final WorkPattern? current;
  final List<WorkPattern> history;
}
