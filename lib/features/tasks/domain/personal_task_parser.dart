import 'package:shiftly/core/serialization/api_model_parser.dart';

import 'personal_task.dart';

PersonalTask parsePersonalTask(Map<String, Object?> json) {
  final status = ApiModelParser.string(json, 'status');
  if (status != 'OPEN' && status != 'COMPLETED') {
    throw const FormatException('Invalid task status');
  }
  return PersonalTask(
    id: ApiModelParser.string(json, 'id'),
    ownerId: ApiModelParser.string(json, 'ownerId'),
    workspaceId: ApiModelParser.string(json, 'workspaceId'),
    title: ApiModelParser.string(json, 'title'),
    description: json['description'] as String,
    dueAt: ApiModelParser.date(json, 'dueAt'),
    revision: ApiModelParser.integer(json, 'revision', minimum: 1),
    completed: status == 'COMPLETED',
    durationMinutes: json['durationMinutes'] == null
        ? null
        : ApiModelParser.integer(json, 'durationMinutes', minimum: 1),
    remindDayBefore: json['remindDayBefore'] == true,
    remindHourBefore: json['remindHourBefore'] == true,
    additionalDueAts: json['additionalDueAts'] == null
        ? const []
        : ApiModelParser.list(json['additionalDueAts'])
              .map((date) => ApiModelParser.date({'date': date}, 'date'))
              .toList(),
  );
}
