import 'package:shiftly/core/serialization/api_model_parser.dart';

import 'support_reply.dart';

export 'support_reply.dart';

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
  bool get canReply => status != 'CLOSED';
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
