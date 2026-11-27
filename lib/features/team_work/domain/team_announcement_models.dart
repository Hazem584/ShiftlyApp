import 'package:shiftly/core/serialization/api_model_parser.dart';

Map<String, Object?> workMap(Object? value) =>
    Map<String, Object?>.from(value as Map);
String workName(Object? value) =>
    (workMap(workMap(value)['profile'])['fullName'] as String?) ?? '';
DateTime? workDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

class WorkPage<T> {
  const WorkPage(this.items, this.total, {this.notice});
  final List<T> items;
  final int total;
  final String? notice;
  factory WorkPage.fromJson(
    Object? value,
    T Function(Map<String, Object?>) parse,
  ) {
    final json = workMap(value);
    return WorkPage(
      (json['data'] as List)
          .map((e) => parse(workMap(e)))
          .toList(growable: false),
      json['total'] as int,
    );
  }
}

class WorkTask {
  WorkTask.fromJson(Map<String, Object?> json)
    : id = ApiModelParser.string(json, 'id'),
      kind = ApiModelParser.string(json, 'kind'),
      name = json['name'] as String? ?? '',
      detail = json['detail'] as String?,
      minutesLate = json['minutesLate'] as int?,
      startsAt = workDate(json['startsAt']),
      endsAt = workDate(json['endsAt']),
      createdAt = DateTime.parse(json['createdAt'] as String);
  final String id, kind, name;
  final String? detail;
  final int? minutesLate;
  final DateTime createdAt;
  final DateTime? startsAt, endsAt;
  bool get needsDecision =>
      ['ATTENDANCE', 'LEAVE', 'CORRECTION'].contains(kind);
}

class TeamAnnouncement {
  TeamAnnouncement.fromJson(Map<String, Object?> json)
    : id = ApiModelParser.string(json, 'id'),
      title = ApiModelParser.string(json, 'title'),
      body = ApiModelParser.string(json, 'body'),
      author = workName(json['author']),
      createdAt = workDate(json['createdAt'])!,
      requiresAcknowledgment = json['requiresAcknowledgment'] as bool,
      readAt = json['receipt'] == null
          ? null
          : workDate(workMap(json['receipt'])['readAt']),
      acknowledgedAt = json['receipt'] == null
          ? null
          : workDate(workMap(json['receipt'])['acknowledgedAt']);
  final String id, title, body, author;
  final DateTime createdAt;
  final bool requiresAcknowledgment;
  final DateTime? readAt, acknowledgedAt;
}

class AnnouncementReader {
  AnnouncementReader.fromJson(Map<String, Object?> json)
    : name = workName(json['membership']),
      readAt = workDate(json['readAt']),
      acknowledgedAt = workDate(json['acknowledgedAt']);
  final String name;
  final DateTime? readAt, acknowledgedAt;
}
