import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';

class ApiWorkLocationRepository implements WorkLocationRepository {
  ApiWorkLocationRepository(this._dio);
  final Dio _dio;
  String _p(String w, [String? id]) =>
      '/workspaces/$w/work-locations${id == null ? '' : '/$id'}';

  @override
  Future<(String, String)> getWorkspacePolicies(String w) => _run(() async {
    final res = await _dio.get<Object?>('/workspaces/$w');
    final json = ApiModelParser.map(res.data);
    return (
      ApiModelParser.optionalString(json['geofenceMode']) ?? 'OFF',
      ApiModelParser.optionalString(json['selfieMode']) ?? 'OFF',
    );
  });

  @override
  Future<(String, String)> updateWorkspacePolicies(
    String w, {
    String? geofenceMode,
    String? selfieMode,
  }) => _run(() async {
    final res = await _dio.patch<Object?>(
      '/workspaces/$w/geofence',
      data: {'geofenceMode': ?geofenceMode, 'selfieMode': ?selfieMode},
    );
    final json = ApiModelParser.map(res.data);
    return (
      ApiModelParser.optionalString(json['geofenceMode']) ??
          geofenceMode ??
          'OFF',
      ApiModelParser.optionalString(json['selfieMode']) ?? selfieMode ?? 'OFF',
    );
  });

  @override
  Future<List<WorkspaceWorkLocation>> list(
    String w, {
    bool includeArchived = false,
  }) => _run(() async {
    final res = await _dio.get<Object?>(
      _p(w),
      queryParameters: {'includeArchived': includeArchived},
    );
    return ApiModelParser.list(res.data).map((e) => _parse(e, w)).toList();
  });

  @override
  Future<WorkspaceWorkLocation> create(
    String w, {
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) => _run(() async {
    final res = await _dio.post<Object?>(
      _p(w),
      data: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      },
    );
    return _parse(res.data, w);
  });

  @override
  Future<WorkspaceWorkLocation> update(
    String w,
    String id, {
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) => _run(() async {
    final res = await _dio.patch<Object?>(
      _p(w, id),
      data: {
        'name': ?name,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'radiusMeters': ?radiusMeters,
      },
    );
    return _parse(res.data, w);
  });

  @override
  Future<WorkspaceWorkLocation> archive(String w, String id) => _run(() async {
    final res = await _dio.delete<Object?>(_p(w, id));
    return _parse(res.data, w);
  });

  WorkspaceWorkLocation _parse(Object? data, String w) =>
      WorkspaceWorkLocation.fromJson(
        ApiModelParser.map(data),
        fallbackWorkspaceId: w,
      );

  Future<T> _run<T>(Future<T> Function() op) async {
    try {
      return await op();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }
}
