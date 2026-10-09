import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class ApiShiftRepository implements ShiftRepository {
  ApiShiftRepository(this._dio);
  final Dio _dio;

  @override
  Future<ShiftPage> listWorkspaceShifts(String workspaceId, ShiftQuery query) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/workspaces/$workspaceId/shifts',
          queryParameters: query.toQuery(),
        );
        return _page(response.data);
      });

  @override
  Future<ShiftRecord> getWorkspaceShift(String workspaceId, String shiftId) =>
      _object(
        () => _dio.get<Object?>('/workspaces/$workspaceId/shifts/$shiftId'),
      );

  @override
  Future<ShiftRecord> createShift(String workspaceId, CreateShiftInput input) =>
      _object(
        () => _dio.post<Object?>(
          '/workspaces/$workspaceId/shifts',
          data: input.toJson(),
        ),
      );

  @override
  Future<ShiftRecord> updateShift(
    String workspaceId,
    String shiftId,
    UpdateShiftInput input,
  ) => _object(
    () => _dio.patch<Object?>(
      '/workspaces/$workspaceId/shifts/$shiftId',
      data: input.toJson(),
    ),
  );

  @override
  Future<ShiftRecord> cancelShift(String workspaceId, String shiftId) =>
      _object(
        () => _dio.patch<Object?>(
          '/workspaces/$workspaceId/shifts/$shiftId/cancel',
        ),
      );

  @override
  Future<ShiftPage> listMyShifts(String workspaceId, ShiftQuery query) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/shifts/me',
          queryParameters: {
            ...query.toQuery(includeEmployee: false),
            'workspaceId': workspaceId,
          },
        );
        return _page(response.data);
      });

  @override
  Future<ShiftRecord> getMyShift(String shiftId) =>
      _object(() => _dio.get<Object?>('/shifts/me/$shiftId'));

  Future<ShiftRecord> _object(Future<Response<Object?>> Function() operation) =>
      _request(() async {
        final response = await operation();
        return ShiftRecord.fromJson(ApiModelParser.map(response.data));
      });

  ShiftPage _page(Object? value) {
    final json = ApiModelParser.map(value);
    return ShiftPage(
      data: ApiModelParser.list(json['data'], 'data')
          .map((item) => ShiftRecord.fromJson(ApiModelParser.map(item)))
          .toList(growable: false),
      pagination: ApiPagination.fromJson(
        ApiModelParser.map(json['pagination'], 'pagination'),
      ),
    );
  }

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
