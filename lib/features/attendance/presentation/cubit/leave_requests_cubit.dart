import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/models/attendance_request.dart';
import 'package:shiftly/core/models/leave_request.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

sealed class LeaveRequestsState extends Equatable {
  const LeaveRequestsState();
  @override
  List<Object?> get props => [];
}

final class LeaveRequestsLoading extends LeaveRequestsState {
  const LeaveRequestsLoading();
}

final class LeaveRequestsLoaded extends LeaveRequestsState {
  const LeaveRequestsLoaded(this.requests, {this.updatingId});
  final List<LeaveRequest> requests;
  final String? updatingId;
  int get pendingCount => requests
      .where((request) => request.status == RequestStatus.pending)
      .length;
  @override
  List<Object?> get props => [requests, updatingId];
}

final class LeaveRequestsError extends LeaveRequestsState {
  const LeaveRequestsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class LeaveRequestsCubit extends Cubit<LeaveRequestsState> {
  LeaveRequestsCubit(this._repository) : super(const LeaveRequestsLoading());
  final LeaveRequestRepository _repository;

  Future<void> load() async {
    emit(const LeaveRequestsLoading());
    try {
      emit(LeaveRequestsLoaded(await _repository.getRequests()));
    } catch (_) {
      emit(const LeaveRequestsError('Unable to load leave requests.'));
    }
  }

  Future<bool> decide(String id, RequestStatus status) async {
    final current = state;
    if (current is! LeaveRequestsLoaded || current.updatingId != null) {
      return false;
    }
    emit(LeaveRequestsLoaded(current.requests, updatingId: id));
    try {
      final updated = await _repository.updateStatus(id, status);
      emit(
        LeaveRequestsLoaded([
          for (final request in current.requests)
            if (request.id == id) updated else request,
        ]),
      );
      return true;
    } catch (_) {
      emit(LeaveRequestsLoaded(current.requests));
      return false;
    }
  }
}
