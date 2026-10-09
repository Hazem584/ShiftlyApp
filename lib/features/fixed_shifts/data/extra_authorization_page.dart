import 'package:shiftly/core/network/api_model_parser.dart';

import 'extra_authorization.dart';

class ExtraAuthorizationPage {
  const ExtraAuthorizationPage(this.data, this.pagination);
  final List<ExtraAuthorization> data;
  final ApiPagination pagination;
}
