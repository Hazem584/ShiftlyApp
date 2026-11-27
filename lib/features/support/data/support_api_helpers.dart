import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/support_models.dart';

SupportPage parseSupportPage(Object? data) {
  final j = ApiModelParser.map(data);
  return SupportPage(
    ApiModelParser.list(
      j['items'],
      'items',
    ).map((v) => SupportTicket.fromJson(ApiModelParser.map(v))).toList(),
    j['hasNext'] == true,
  );
}

List<SupportContext> parseSupportContexts(Object? data) {
  final j = ApiModelParser.map(data);
  return ApiModelParser.list(
    j['items'],
    'items',
  ).map((v) => SupportContext.fromJson(ApiModelParser.map(v))).toList();
}

Map<String, Object?> buildSupportCreatePayload({
  required String workspaceId,
  required String clientId,
  required String title,
  required String description,
  SupportContext? related,
}) => {
  'workspaceId': workspaceId,
  'clientId': clientId,
  'title': title,
  'description': description,
  if (related != null) ...{
    'relatedKind': related.kind,
    'relatedId': related.id,
  },
};

FormData buildSupportImageForm(Uint8List bytes, String mime) =>
    FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: 'support-image.${mime.split('/').last}',
        contentType: DioMediaType.parse(mime),
      ),
    });
