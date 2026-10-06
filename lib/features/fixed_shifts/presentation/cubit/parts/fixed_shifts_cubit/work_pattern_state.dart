part of '../../fixed_shifts_cubit.dart';

class WorkPatternState extends Equatable {
  const WorkPatternState({
    this.loading = true,
    this.saving = false,
    this.history,
    this.failure,
  });
  final bool loading;
  final bool saving;
  final WorkPatternHistory? history;
  final Failure? failure;
  @override
  List<Object?> get props => [
    loading,
    saving,
    history?.current,
    history?.history,
    failure?.message,
    failure?.requestId,
  ];
}
