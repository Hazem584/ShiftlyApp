import 'package:shiftly/core/serialization/api_model_parser.dart';

class SupportContext {
  const SupportContext({
    required this.id,
    required this.kind,
    required this.label,
  });
  final String id, kind, label;
  factory SupportContext.fromJson(Map<String, Object?> j) => SupportContext(
    id: ApiModelParser.string(j, 'id'),
    kind: ApiModelParser.string(j, 'kind'),
    label: ApiModelParser.string(j, 'label'),
  );
}

class SupportReply {
  const SupportReply({
    required this.id,
    required this.body,
    required this.staff,
    required this.createdAt,
    required this.author,
  });
  final String id, body, author;
  final bool staff;
  final DateTime createdAt;
  factory SupportReply.fromJson(Map<String, Object?> j) => SupportReply(
    id: ApiModelParser.string(j, 'id'),
    body: ApiModelParser.string(j, 'body'),
    staff: j['authorKind'] == 'STAFF',
    createdAt: ApiModelParser.date(j, 'createdAt'),
    author:
        ApiModelParser.optionalString(
          ApiModelParser.optionalMap(j['author'])?['fullName'],
        ) ??
        '',
  );
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.updatedAt,
    this.assignee,
    this.relatedLabel,
    this.hasImage = false,
    this.replies = const [],
  });
  final String id, title, description, status;
  final String? assignee, relatedLabel;
  final bool hasImage;
  final DateTime updatedAt;
  final List<SupportReply> replies;
  factory SupportTicket.fromJson(Map<String, Object?> j) => SupportTicket(
    id: ApiModelParser.string(j, 'id'),
    title: ApiModelParser.string(j, 'title'),
    description: ApiModelParser.string(j, 'description'),
    status: ApiModelParser.string(j, 'status'),
    updatedAt: ApiModelParser.date(j, 'updatedAt'),
    assignee: ApiModelParser.optionalString(
      ApiModelParser.optionalMap(j['assignee'])?['fullName'],
    ),
    relatedLabel: ApiModelParser.optionalString(j['relatedLabel']),
    hasImage: j['hasImage'] == true,
    replies: j['replies'] == null
        ? const []
        : ApiModelParser.list(
            j['replies'],
            'replies',
          ).map((v) => SupportReply.fromJson(ApiModelParser.map(v))).toList(),
  );
}

class SupportPage {
  const SupportPage(this.items, this.hasNext);
  final List<SupportTicket> items;
  final bool hasNext;
}

String supportStatusLabel(String value) => switch (value) {
  'IN_PROGRESS' => 'In progress',
  'WAITING_REPORTER' => 'Waiting for your reply',
  'RESOLVED' => 'Resolved',
  'CLOSED' => 'Closed',
  _ => 'Open',
};
