part of '../../employee_details_cubit.dart';

class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit(this._repository)
    : super(const EmployeeDetailsLoadingState());
  final EmployeeRepository _repository;
  var _generation = 0;

  Future<void> load({
    required String workspaceId,
    required String membershipId,
    bool retain = false,
  }) async {
    final generation = ++_generation;
    if (!retain || state is! EmployeeDetailsLoadedState) {
      emit(const EmployeeDetailsLoadingState());
    }
    try {
      final employee = await _repository.getWorkspaceEmployee(
        workspaceId: workspaceId,
        membershipId: membershipId,
      );
      if (!isClosed && generation == _generation) {
        emit(EmployeeDetailsLoadedState(employee));
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          EmployeeDetailsErrorState(
            error is ApiException
                ? error.toFailure().message
                : 'Unable to load this employee.',
          ),
        );
      }
    }
  }
}
