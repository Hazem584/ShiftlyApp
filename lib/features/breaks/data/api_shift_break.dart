import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/shift_break_state.dart';

class ApiShiftBreak {
  ApiShiftBreak(this.dio);
  final Dio dio;
  Future<ShiftBreakState> change(String id, bool end, int revision) =>
      _change(id, end ? 'end' : 'start', revision: revision);
  Future<ShiftBreakState> start(String id) => _change(id, 'start');
  Future<ShiftBreakState> end(String id) => _change(id, 'end');
  Future<ShiftBreakState> _change(
    String id,
    String action, {
    int? revision,
  }) async {
    final response = await dio.post<Object?>(
      '/attendance/$id/break/$action',
      data: {'expectedRevision': ?revision},
    );
    final json = ApiModelParser.map(response.data);
    return ShiftBreakState.fromJson(ApiModelParser.map(json['breakState']));
  }
}
