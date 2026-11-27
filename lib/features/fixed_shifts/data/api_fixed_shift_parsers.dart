import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

Future<T> requestFixedShift<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } catch (error) {
    throw ApiErrorParser.parse(error);
  }
}

WorkPatternHistory parseWorkPatternHistory(Object? data) {
  final json = ApiModelParser.map(data);
  final currentJson = ApiModelParser.optionalMap(json['current'], 'current');
  return WorkPatternHistory(
    pagination: ApiPagination.fromJson(ApiModelParser.map(json['pagination'])),
    current: currentJson == null ? null : WorkPattern.fromJson(currentJson),
    history: ApiModelParser.list(json['history'], 'history')
        .map((value) => WorkPattern.fromJson(ApiModelParser.map(value)))
        .toList(growable: false),
  );
}

List<int> validateExpectedWeekdays(List<int> expectedWeekdays) {
  final unique = expectedWeekdays.toSet().toList()..sort();
  if (unique.length != expectedWeekdays.length ||
      unique.isEmpty ||
      unique.any((value) => value < 0 || value > 6)) {
    throw const FormatException('Invalid expected weekdays');
  }
  return unique;
}

ShiftTemplatePage parseShiftTemplatePage(Object? data) {
  final json = ApiModelParser.map(data);
  return ShiftTemplatePage(
    data: ApiModelParser.list(json['data'], 'data')
        .map((value) => ShiftTemplate.fromJson(ApiModelParser.map(value)))
        .toList(growable: false),
    pagination: ApiPagination.fromJson(
      ApiModelParser.map(json['pagination'], 'pagination'),
    ),
  );
}

ExtraAuthorizationPage parseExtraAuthorizationPage(Object? data) {
  final json = ApiModelParser.map(data);
  return ExtraAuthorizationPage(
    ApiModelParser.list(
      json['data'],
      'data',
    ).map((v) => ExtraAuthorization(ApiModelParser.map(v))).toList(),
    ApiPagination.fromJson(ApiModelParser.map(json['pagination'])),
  );
}
