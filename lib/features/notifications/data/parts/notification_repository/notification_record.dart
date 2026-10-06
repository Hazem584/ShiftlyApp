part of '../../notification_repository.dart';

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
