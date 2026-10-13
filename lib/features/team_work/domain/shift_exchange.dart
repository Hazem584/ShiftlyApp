import 'package:shiftly/core/serialization/api_model_parser.dart';

class ShiftExchange {
  ShiftExchange.fromJson(Map<String, Object?> j)
    : id = ApiModelParser.string(j, 'id'),
      workspaceId = ApiModelParser.string(j, 'workspaceId'),
      kind = ApiModelParser.string(j, 'kind'),
      status = ApiModelParser.string(j, 'status'),
      reason = ApiModelParser.string(j, 'reason'),
      requesterId = ApiModelParser.string(j, 'requesterMembershipId'),
      targetId = ApiModelParser.string(j, 'targetMembershipId'),
      requesterDate = ApiModelParser.string(j, 'requesterDate'),
      targetDate = ApiModelParser.string(j, 'targetDate'),
      requester = ApiModelParser.map(j['requesterSnapshot']),
      target = ApiModelParser.map(j['targetSnapshot']),
      expiresAt = ApiModelParser.date(j, 'expiresAt'),
      createdAt = ApiModelParser.date(j, 'createdAt'),
      peerNote = ApiModelParser.optionalString(j['peerNote']),
      reviewNote = ApiModelParser.optionalString(j['reviewNote']),
      reviewer = j['reviewer'] == null
          ? null
          : ApiModelParser.optionalString(
              ApiModelParser.map(
                ApiModelParser.map(j['reviewer'])['profile'],
              )['fullName'],
            );
  final String id,
      workspaceId,
      kind,
      status,
      reason,
      requesterId,
      targetId,
      requesterDate,
      targetDate;
  final Map<String, Object?> requester, target;
  final DateTime expiresAt, createdAt;
  final String? peerNote, reviewNote, reviewer;
  bool get pending => ['PENDING_PEER', 'PENDING_MANAGER'].contains(status);
  bool get expired => pending && !expiresAt.isAfter(DateTime.now());
}

class ExchangeColleague {
  const ExchangeColleague(this.id, this.name);
  final String id, name;
}
