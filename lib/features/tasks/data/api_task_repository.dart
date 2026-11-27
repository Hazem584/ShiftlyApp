import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/personal_task.dart';
import '../domain/task_repository.dart';
import 'api_task_payloads.dart';
import 'api_task_requests.dart';

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._dio);
  final Dio _dio;
  @override
  Future<TaskPage> list({required bool completed, required int page}) =>
      fetchApiTaskPage(_dio, completed: completed, page: page);
  @override
  Future<List<PersonalTask>> upcoming() => runTaskApiRequest(
    () async => parseTaskItems(
      (await _dio.get<Object?>('$personalTasksPath/upcoming')).data,
    ),
  );
  @override
  Future<PersonalTask> get(String id) => runTaskApiRequest(
    () async => PersonalTask.fromJson(
      ApiModelParser.map(
        (await _dio.get<Object?>('$personalTasksPath/$id')).data,
      ),
    ),
  );
  @override
  Future<void> create({
    required String workspaceId,
    required String title,
    required String description,
    required DateTime dueAt,
    int? durationMinutes,
    bool remindDayBefore = false,
    bool remindHourBefore = false,
    List<DateTime> additionalDueAts = const [],
  }) => postApiTask(
    _dio,
    buildCreateTaskPayload(
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueAt: dueAt,
      durationMinutes: durationMinutes,
      remindDayBefore: remindDayBefore,
      remindHourBefore: remindHourBefore,
      additionalDueAts: additionalDueAts,
    ),
  );
  @override
  Future<void> update(
    PersonalTask task, {
    String? title,
    String? description,
    DateTime? dueAt,
    bool? completed,
    int? durationMinutes,
    bool? remindDayBefore,
    bool? remindHourBefore,
    List<DateTime>? additionalDueAts,
  }) => patchApiTask(
    _dio,
    task.id,
    buildUpdateTaskPayload(
      task,
      title: title,
      description: description,
      dueAt: dueAt,
      completed: completed,
      durationMinutes: durationMinutes,
      remindDayBefore: remindDayBefore,
      remindHourBefore: remindHourBefore,
      additionalDueAts: additionalDueAts,
    ),
  );
  @override
  Future<void> remove(PersonalTask task) => runTaskApiRequest(
    () => _dio.delete<Object?>(
      '$personalTasksPath/${task.id}',
      queryParameters: {'revision': task.revision},
    ),
  );
  @override
  Future<void> register(String installationId, List<PersonalTask> scheduled) =>
      registerApiTaskReminders(_dio, installationId, scheduled);
}
