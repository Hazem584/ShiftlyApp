import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';

class ManagerResourceState {
  const ManagerResourceState({
    this.records = const [],
    this.object,
    this.loading = false,
    this.error,
    this.page = 0,
    this.hasMore = false,
    this.query = const {},
  });
  final List<ManagerPointsRecord> records;
  final Map<String, Object?>? object;
  final bool loading, hasMore;
  final String? error;
  final int page;
  final Map<String, Object?> query;
}
