import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_parsers.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

abstract class ApiFixedShiftTemplateClient implements FixedShiftRepository {
  Dio get dio;

  @override
  Future<ShiftTemplatePage> listTemplates(
    String workspaceId, {
    bool includeArchived = false,
    int page = 1,
    int limit = 100,
  }) => _page(
    () => dio.get<Object?>(
      '/workspaces/$workspaceId/shift-templates',
      queryParameters: {
        'page': page,
        'limit': limit,
        'includeArchived': includeArchived,
      },
    ),
  );

  @override
  Future<ShiftTemplatePage> listMyTemplates(
    String workspaceId, {
    int page = 1,
    int limit = 100,
  }) => _page(
    () => dio.get<Object?>(
      '/shift-templates/me',
      queryParameters: {
        'workspaceId': workspaceId,
        'page': page,
        'limit': limit,
      },
    ),
  );

  @override
  Future<ShiftTemplate> getTemplate(String workspaceId, String templateId) =>
      _template(
        () => dio.get<Object?>(
          '/workspaces/$workspaceId/shift-templates/$templateId',
        ),
      );

  @override
  Future<ShiftTemplate> createTemplate(
    String workspaceId,
    ShiftTemplateInput input,
  ) => _template(
    () => dio.post<Object?>(
      '/workspaces/$workspaceId/shift-templates',
      data: input.toJson(),
    ),
  );

  @override
  Future<ShiftTemplate> updateTemplate(
    String workspaceId,
    String templateId,
    ShiftTemplateInput input,
  ) => _template(
    () => dio.patch<Object?>(
      '/workspaces/$workspaceId/shift-templates/$templateId',
      data: input.toJson(),
    ),
  );

  @override
  Future<ShiftTemplate> archiveTemplate(
    String workspaceId,
    String templateId,
  ) => _template(
    () => dio.delete<Object?>(
      '/workspaces/$workspaceId/shift-templates/$templateId',
    ),
  );

  Future<ShiftTemplate> _template(Future<Response<Object?>> Function() op) =>
      requestFixedShift(
        () async =>
            ShiftTemplate.fromJson(ApiModelParser.map((await op()).data)),
      );
  Future<ShiftTemplatePage> _page(Future<Response<Object?>> Function() op) =>
      requestFixedShift(
        () async => parseShiftTemplatePage((await op()).data),
      );
}
