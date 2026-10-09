import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/shifts/domain/entities/shift_record.dart';

class ShiftPage {
  const ShiftPage({required this.data, required this.pagination});
  final List<ShiftRecord> data;
  final ApiPagination pagination;
}
