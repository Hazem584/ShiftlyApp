import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/operations_repository.dart';

class ApiOperationsRepository implements OperationsRepository {
  ApiOperationsRepository(this._dio);
  final Dio _dio;
  String _path(String w) => '/workspaces/$w/operations';
  Future<OperationMap> _call(
    String w,
    String path, {
    String method = 'GET',
    OperationMap? data,
    OperationMap? query,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        '${_path(w)}/$path',
        data: data,
        queryParameters: query,
        options: Options(method: method, extra: {'skipReadCache': true}),
      );
      final body = ApiModelParser.map(response.data);
      void check(OperationMap row) {
        if (row['workspace_id'] != null && row['workspace_id'] != w) {
          throw const FormatException('Cross-workspace operational data');
        }
      }

      check(body);
      if (body['data'] is List) {
        for (final item in body['data'] as List) {
          if (item is Map) check(ApiModelParser.map(item));
        }
      }
      return body;
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  List<OperationMap> _rows(OperationMap j) =>
      ApiModelParser.list(j['data']).map(ApiModelParser.map).toList();
  @override
  Future<List<OperationMap>> profiles(String w) async =>
      _rows(await _call(w, 'profiles'));
  @override
  Future<void> saveProfile(String w, String id, OperationMap v) async {
    await _call(w, 'profiles/$id', method: 'PUT', data: v);
  }

  @override
  Future<List<OperationMap>> proposals(String w) async =>
      _rows(await _call(w, 'proposals'));
  @override
  Future<OperationMap> generate(String w, OperationMap v) =>
      _call(w, 'proposals', method: 'POST', data: v);
  @override
  Future<OperationMap> approve(String w, String id, OperationMap v) =>
      _call(w, 'proposals/$id/approve', method: 'POST', data: v);
  @override
  Future<List<OperationMap>> occurrences(String w, String from) async =>
      _rows(await _call(w, 'occurrences', query: {'from': from}));
  @override
  Future<OperationMap> handovers(String w, int page) =>
      _call(w, 'handovers', query: {'page': page});
  @override
  Future<OperationMap> handover(String w, String id) =>
      _call(w, 'handovers/$id');
  @override
  Future<OperationMap> createHandover(String w, OperationMap v) =>
      _call(w, 'handovers', method: 'POST', data: v);
  @override
  Future<void> receive(String w, String id, int revision) async {
    await _call(
      w,
      'handovers/$id/receive',
      method: 'POST',
      data: {'revision': revision},
    );
  }

  @override
  Future<void> updateItem(
    String w,
    String id,
    String item,
    OperationMap v,
  ) async {
    await _call(w, 'handovers/$id/items/$item', method: 'POST', data: v);
  }

  @override
  Future<OperationMap> forward(String w, String id, OperationMap v) =>
      _call(w, 'handovers/$id/forward', method: 'POST', data: v);
}
