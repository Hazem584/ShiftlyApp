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

String supportStatusLabel(String value) => switch (value) {
  'IN_PROGRESS' => 'In progress',
  'WAITING_REPORTER' => 'Waiting for your reply',
  'RESOLVED' => 'Resolved',
  'CLOSED' => 'Closed',
  _ => 'Open',
};
