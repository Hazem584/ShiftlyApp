import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

class AttendanceTestCubit extends FlexibleAttendanceCubit {
  AttendanceTestCubit([
    FlexibleAttendanceState initial = const FlexibleAttendanceState(
      loading: false,
    ),
  ]) : super(_UnusedRepository()) {
    emit(initial);
  }

  int refreshes = 0;

  @override
  Future<void> load({bool refresh = false}) async {
    if (refresh) refreshes++;
  }
}

class _UnusedRepository implements FixedShiftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
