part of '../../shift_repository.dart';

class ShiftPage {
  const ShiftPage({required this.data, required this.pagination});
  final List<ShiftRecord> data;
  final ApiPagination pagination;
}
