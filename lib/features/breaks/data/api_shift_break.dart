import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';

import '../domain/shift_break_state.dart';

class ApiShiftBreak {
  ApiShiftBreak(this.dio);
  final Dio dio;
  Future<ShiftBreakState> start(String id) => _change(id, 'start');
  Future<ShiftBreakState> end(String id) => _change(id, 'end');
  Future<ShiftBreakState> _change(String id, String action) async {
    final response = await dio.post<Object?>('/attendance/$id/break/$action');
    final json = ApiModelParser.map(response.data);
    return ShiftBreakState.fromJson(ApiModelParser.map(json['breakState']));
  }
}
