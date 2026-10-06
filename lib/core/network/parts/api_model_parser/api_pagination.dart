part of '../../api_model_parser.dart';

class ApiPagination {
  const ApiPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory ApiPagination.fromJson(Map<String, Object?> json) => ApiPagination(
    page: ApiModelParser.integer(json, 'page', minimum: 1),
    limit: ApiModelParser.integer(json, 'limit', minimum: 1),
    total: ApiModelParser.integer(json, 'total'),
    totalPages: ApiModelParser.integer(json, 'totalPages'),
  );
}
