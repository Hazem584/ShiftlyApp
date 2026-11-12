import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';

class ApiSupportRepository implements SupportRepository {
  ApiSupportRepository(this.dio);
  final Dio dio;
  @override
  Future<SupportPage> list({required int page}) async {
    final j = ApiModelParser.map(
      (await dio.get<Object?>(
        '/support',
        queryParameters: {'page': page},
      )).data,
    );
    return SupportPage(
      ApiModelParser.list(
        j['items'],
        'items',
      ).map((v) => SupportTicket.fromJson(ApiModelParser.map(v))).toList(),
      j['hasNext'] == true,
    );
  }

  @override
  Future<List<SupportContext>> contexts(String workspaceId) async {
    final j = ApiModelParser.map(
      (await dio.get<Object?>(
        '/support/context',
        queryParameters: {'workspaceId': workspaceId},
      )).data,
    );
    return ApiModelParser.list(
      j['items'],
      'items',
    ).map((v) => SupportContext.fromJson(ApiModelParser.map(v))).toList();
  }

  @override
  Future<SupportTicket> get(String id) async => SupportTicket.fromJson(
    ApiModelParser.map((await dio.get<Object?>('/support/$id')).data),
  );
  @override
  Future<SupportTicket> create({
    required String workspaceId,
    required String clientId,
    required String title,
    required String description,
    SupportContext? related,
  }) async {
    final r = await dio.post<Object?>(
      '/support',
      data: {
        'workspaceId': workspaceId,
        'clientId': clientId,
        'title': title,
        'description': description,
        if (related != null) ...{
          'relatedKind': related.kind,
          'relatedId': related.id,
        },
      },
    );
    return SupportTicket.fromJson(ApiModelParser.map(r.data));
  }

  @override
  Future<void> reply({
    required String id,
    required String clientId,
    required String body,
  }) async {
    await dio.post<Object?>(
      '/support/$id/replies',
      data: {'clientId': clientId, 'body': body},
    );
  }

  @override
  Future<void> uploadImage({
    required String id,
    required Uint8List bytes,
    required String mime,
  }) async {
    await dio.post<Object?>(
      '/support/$id/image',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: 'support-image.${mime.split('/').last}',
          contentType: DioMediaType.parse(mime),
        ),
      }),
    );
  }

  @override
  Future<Uint8List> image(String id) async {
    final r = await dio.get<List<int>>(
      '/support/$id/image',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data!);
  }
}
