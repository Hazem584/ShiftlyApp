import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';

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
