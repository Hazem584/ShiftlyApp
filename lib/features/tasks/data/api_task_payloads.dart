import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/personal_task.dart';

List<PersonalTask> parseTaskItems(Object? value) =>
    ApiModelParser.list(value)
        .map((e) => PersonalTask.fromJson(ApiModelParser.map(e)))
        .toList();

TaskPage parseTaskPage(Object? raw) {
  final json = ApiModelParser.map(raw);
  return TaskPage(
    parseTaskItems(json['items']),
    ApiModelParser.integer(json, 'total'),
  );
}

Map<String, Object?> buildCreateTaskPayload({
  required String workspaceId,
  required String title,
  required String description,
  required DateTime dueAt,
  int? durationMinutes,
  required bool remindDayBefore,
  required bool remindHourBefore,
  required List<DateTime> additionalDueAts,
}) => {
  'workspaceId': workspaceId,
  'title': title,
  'description': description,
  'dueAt': dueAt.toUtc().toIso8601String(),
  'durationMinutes': ?durationMinutes,
  'remindDayBefore': remindDayBefore,
  'remindHourBefore': remindHourBefore,
  'additionalDueAts': additionalDueAts
      .map((date) => date.toUtc().toIso8601String())
      .toList(),
};

Map<String, Object?> buildUpdateTaskPayload(
  PersonalTask task, {
  String? title,
  String? description,
  DateTime? dueAt,
  bool? completed,
  int? durationMinutes,
  bool? remindDayBefore,
  bool? remindHourBefore,
  List<DateTime>? additionalDueAts,
}) => {
  'revision': task.revision,
  'title': ?title,
  'description': ?description,
  'durationMinutes': ?durationMinutes,
  'remindDayBefore': ?remindDayBefore,
  'remindHourBefore': ?remindHourBefore,
  if (additionalDueAts != null)
    'additionalDueAts': additionalDueAts
        .map((date) => date.toUtc().toIso8601String())
        .toList(),
  if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
  if (completed != null) 'status': completed ? 'COMPLETED' : 'OPEN',
};

Map<String, Object?> buildReminderRegistrationPayload(
  String installationId,
  List<PersonalTask> scheduled,
) => {
  'installationId': installationId,
  'tasks': scheduled
      .map((t) => {'id': t.id, 'revision': t.revision, 'coverageVersion': 4})
      .toList(),
};
