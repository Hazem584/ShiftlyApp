part of '../../fixed_shifts_cubit.dart';

class ManagerTemplatesState extends Equatable {
  const ManagerTemplatesState({
    this.loading = true,
    this.refreshing = false,
    this.templates = const [],
    this.includeArchived = false,
    this.saving = false,
    this.archivingId,
    this.failure,
  });
  final bool loading;
  final bool refreshing;
  final List<ShiftTemplate> templates;
  final bool includeArchived;
  final bool saving;
  final String? archivingId;
  final Failure? failure;

  ManagerTemplatesState copyWith({
    bool? loading,
    bool? refreshing,
    List<ShiftTemplate>? templates,
    bool? includeArchived,
    bool? saving,
    String? archivingId,
    bool clearArchiving = false,
    Failure? failure,
    bool clearFailure = false,
  }) => ManagerTemplatesState(
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    templates: templates ?? this.templates,
    includeArchived: includeArchived ?? this.includeArchived,
    saving: saving ?? this.saving,
    archivingId: clearArchiving ? null : archivingId ?? this.archivingId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    refreshing,
    templates,
    includeArchived,
    saving,
    archivingId,
    failure?.message,
    failure?.requestId,
  ];
}
