import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

enum NotificationType {
  attendanceClockedIn,
  attendanceClockedOut,
  leaveRequestCreated,
  leaveRequestApproved,
  leaveRequestRejected,
  shiftAssigned,
  shiftUpdated,
  shiftCancelled,
  unknown;

  static NotificationType parse(Object? value) => switch (value) {
    'ATTENDANCE_CLOCKED_IN' => attendanceClockedIn,
    'ATTENDANCE_CLOCKED_OUT' => attendanceClockedOut,
    'LEAVE_REQUEST_CREATED' => leaveRequestCreated,
    'LEAVE_REQUEST_APPROVED' => leaveRequestApproved,
    'LEAVE_REQUEST_REJECTED' => leaveRequestRejected,
    'SHIFT_ASSIGNED' => shiftAssigned,
    'SHIFT_UPDATED' => shiftUpdated,
    'SHIFT_CANCELLED' => shiftCancelled,
    _ => unknown,
  };

  String? get apiValue => switch (this) {
    attendanceClockedIn => 'ATTENDANCE_CLOCKED_IN',
    attendanceClockedOut => 'ATTENDANCE_CLOCKED_OUT',
    leaveRequestCreated => 'LEAVE_REQUEST_CREATED',
    leaveRequestApproved => 'LEAVE_REQUEST_APPROVED',
    leaveRequestRejected => 'LEAVE_REQUEST_REJECTED',
    shiftAssigned => 'SHIFT_ASSIGNED',
    shiftUpdated => 'SHIFT_UPDATED',
    shiftCancelled => 'SHIFT_CANCELLED',
    unknown => null,
  };
}

class NotificationRecord extends Equatable {
  const NotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.workspaceId,
    this.data,
    this.readAt,
  });

  final String id;
  final String? workspaceId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, Object?>? data;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUnread => readAt == null;

  factory NotificationRecord.fromJson(Map<String, Object?> json) {
    final rawData = json['data'];
    return NotificationRecord(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.optionalString(json['workspaceId']),
      type: NotificationType.parse(json['type']),
      title: ApiModelParser.string(json, 'title'),
      message: ApiModelParser.string(json, 'message'),
      data: ApiModelParser.optionalMap(rawData, 'notification.data'),
      readAt: ApiModelParser.optionalDate(json['readAt']),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      updatedAt: ApiModelParser.date(json, 'updatedAt'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    workspaceId,
    type,
    title,
    message,
    data,
    readAt,
    createdAt,
    updatedAt,
  ];
}

class NotificationPage {
  const NotificationPage({required this.data, required this.pagination});
  final List<NotificationRecord> data;
  final ApiPagination pagination;
}

class NotificationQuery {
  const NotificationQuery({
    this.page = 1,
    this.limit = 20,
    this.unread,
    this.type,
  });

  final int page;
  final int limit;
  final bool? unread;
  final NotificationType? type;

  NotificationQuery copyWith({int? page}) => NotificationQuery(
    page: page ?? this.page,
    limit: limit,
    unread: unread,
    type: type,
  );
}

abstract interface class NotificationRepository {
  Future<NotificationPage> list(String workspaceId, NotificationQuery query);
  Future<int> unreadCount();
  Future<NotificationRecord> markRead(String notificationId);
  Future<int> markAllRead(String workspaceId);
  Future<bool> delete(String notificationId);
}
