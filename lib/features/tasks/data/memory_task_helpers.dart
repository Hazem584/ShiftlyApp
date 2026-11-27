import 'package:uuid/uuid.dart';

import '../domain/personal_task.dart';

PersonalTask buildCreatedMemoryTask({
  required String workspaceId,
  required String title,
  required String description,
  required DateTime dueAt,
  int? durationMinutes,
  bool remindDayBefore = false,
  bool remindHourBefore = false,
  List<DateTime> additionalDueAts = const [],
}) => PersonalTask(
  id: const Uuid().v4(),
  ownerId: 'preview-user',
  workspaceId: workspaceId,
  title: title,
  description: description,
  dueAt: dueAt,
  revision: 1,
  completed: false,
  durationMinutes: durationMinutes,
  remindDayBefore: remindDayBefore,
  remindHourBefore: remindHourBefore,
  additionalDueAts: List.unmodifiable(additionalDueAts),
);

PersonalTask buildUpdatedMemoryTask(
  PersonalTask task, {
  String? title,
  String? description,
  DateTime? dueAt,
  bool? completed,
  int? durationMinutes,
  bool? remindDayBefore,
  bool? remindHourBefore,
  List<DateTime>? additionalDueAts,
}) => PersonalTask(
  id: task.id,
  ownerId: task.ownerId,
  workspaceId: task.workspaceId,
  title: title ?? task.title,
  description: description ?? task.description,
  dueAt: dueAt ?? task.dueAt,
  revision: task.revision + 1,
  completed: completed ?? task.completed,
  durationMinutes: durationMinutes ?? task.durationMinutes,
  remindDayBefore: remindDayBefore ?? task.remindDayBefore,
  remindHourBefore: remindHourBefore ?? task.remindHourBefore,
  additionalDueAts: List.unmodifiable(
    additionalDueAts ?? task.additionalDueAts,
  ),
);
