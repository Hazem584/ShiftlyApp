import 'package:shiftly/core/serialization/api_model_parser.dart';

class PersonalTask {
  const PersonalTask({
    required this.id,
    required this.ownerId,
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.revision,
    required this.completed,
  });
  final String id, ownerId, workspaceId, title, description;
  final DateTime dueAt;
  final int revision;
  final bool completed;
  bool get overdue => !completed && dueAt.isBefore(DateTime.now());
  factory PersonalTask.fromJson(Map<String, Object?> json) {
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
    );
  }
}

class TaskPage {
  const TaskPage(this.items, this.total);
  final List<PersonalTask> items;
  final int total;
}
