import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';

class ShiftTemplatePage {
  const ShiftTemplatePage({required this.data, required this.pagination});
  final List<ShiftTemplate> data;
  final ApiPagination pagination;
}
