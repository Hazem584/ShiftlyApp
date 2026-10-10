import 'package:equatable/equatable.dart';

enum ReadCategory { schedule, attendance }

class ReadSyncStatus extends Equatable {
  const ReadSyncStatus({
    this.pending = 0,
    this.updatedAt,
    this.usingSaved = false,
    this.failed = false,
  });
  final int pending;
  final DateTime? updatedAt;
  final bool usingSaved;
  final bool failed;
  @override
  List<Object?> get props => [pending, updatedAt, usingSaved, failed];
}

class ReadSyncState extends Equatable {
  const ReadSyncState(this.statuses);
  final Map<ReadCategory, ReadSyncStatus> statuses;
  @override
  List<Object?> get props => [statuses];
}
