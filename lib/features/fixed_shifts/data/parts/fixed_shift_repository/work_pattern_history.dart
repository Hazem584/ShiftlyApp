part of '../../fixed_shift_repository.dart';

class WorkPatternHistory {
  const WorkPatternHistory({required this.current, required this.history});
  final WorkPattern? current;
  final List<WorkPattern> history;
}
