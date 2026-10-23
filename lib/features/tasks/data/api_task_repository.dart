import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/personal_task.dart';
import '../domain/task_repository.dart';

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._dio);
  final Dio _dio;
  static const _path = '/personal-tasks';
  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  List<PersonalTask> _items(Object? value) =>
      ApiModelParser.list(value)
          .map((e) => PersonalTask.fromJson(ApiModelParser.map(e)))
          .toList();
  @override
  Future<TaskPage> list({required bool completed, required int page}) =>
      _request(() async {
        final json = ApiModelParser.map(
          (await _dio.get<Object?>(
            _path,
            queryParameters: {
              'status': completed ? 'COMPLETED' : 'OPEN',
              'page': page,
              'limit': 30,
            },
          )).data,
        );
        return TaskPage(
          _items(json['items']),
          ApiModelParser.integer(json, 'total'),
        );
      });
  @override
  Future<List<PersonalTask>> upcoming() => _request(
    () async => _items((await _dio.get<Object?>('$_path/upcoming')).data),
  );
  @override
  Future<PersonalTask> get(String id) => _request(
    () async => PersonalTask.fromJson(
      ApiModelParser.map((await _dio.get<Object?>('$_path/$id')).data),
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
  }) => _request(() async {
    await _dio.post<Object?>(
      _path,
      data: {
        'workspaceId': workspaceId,
        'title': title,
        'description': description,
        'dueAt': dueAt.toUtc().toIso8601String(),
        'durationMinutes': ?durationMinutes,
        'remindDayBefore': remindDayBefore,
        'remindHourBefore': remindHourBefore,
      },
    );
  });
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
  }) => _request(() async {
    await _dio.patch<Object?>(
      '$_path/${task.id}',
      data: {
        'revision': task.revision,
        'title': ?title,
        'description': ?description,
        'durationMinutes': ?durationMinutes,
        'remindDayBefore': ?remindDayBefore,
        'remindHourBefore': ?remindHourBefore,
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
        if (completed != null) 'status': completed ? 'COMPLETED' : 'OPEN',
      },
    );
  });
  @override
  Future<void> remove(PersonalTask task) => _request(() async {
    await _dio.delete<Object?>(
      '$_path/${task.id}',
      queryParameters: {'revision': task.revision},
    );
  });
  @override
  Future<void> register(String installationId, List<PersonalTask> scheduled) =>
      _request(() async {
        await _dio.post<Object?>(
          '$_path/reminder-registrations',
          data: {
            'installationId': installationId,
            'tasks': scheduled
                .map(
                  (t) => {
                    'id': t.id,
                    'revision': t.revision,
                    'coverageVersion': 3,
                  },
                )
                .toList(),
          },
        );
      });
}
