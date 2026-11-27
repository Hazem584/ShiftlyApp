import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';

import '../domain/personal_task.dart';
import 'api_task_payloads.dart';

const personalTasksPath = '/personal-tasks';

Future<T> runTaskApiRequest<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    throw ApiErrorParser.parse(error);
  }
}

Future<TaskPage> fetchApiTaskPage(
  Dio dio, {
  required bool completed,
  required int page,
}) => runTaskApiRequest(() async {
  final res = await dio.get<Object?>(
    personalTasksPath,
    queryParameters: {
      'status': completed ? 'COMPLETED' : 'OPEN',
      'page': page,
      'limit': 30,
    },
  );
  return parseTaskPage(res.data);
});

Future<void> postApiTask(Dio dio, Map<String, Object?> payload) =>
    runTaskApiRequest(() => dio.post<Object?>(personalTasksPath, data: payload));

Future<void> patchApiTask(Dio dio, String id, Map<String, Object?> payload) =>
    runTaskApiRequest(
      () => dio.patch<Object?>('$personalTasksPath/$id', data: payload),
    );

Future<void> registerApiTaskReminders(
  Dio dio,
  String installationId,
  List<PersonalTask> scheduled,
) => runTaskApiRequest(
  () => dio.post<Object?>(
    '$personalTasksPath/reminder-registrations',
    data: buildReminderRegistrationPayload(installationId, scheduled),
  ),
);
