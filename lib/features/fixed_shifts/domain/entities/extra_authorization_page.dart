import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';

class ExtraAuthorizationPage {
  const ExtraAuthorizationPage(this.data, this.pagination);
  final List<ExtraAuthorization> data;
  final ApiPagination pagination;
}
