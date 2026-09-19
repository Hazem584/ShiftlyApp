import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.data);
  final DashboardData data;
  @override
  List<Object?> get props => [data];
}

final class DashboardEmpty extends DashboardState {
  const DashboardEmpty();
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardLoading());
  final DashboardRepository _repository;

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      final data = await _repository.getDashboard();
      emit(data.isEmpty ? const DashboardEmpty() : DashboardLoaded(data));
    } catch (_) {
      emit(
        const DashboardError(
          'We could not load your dashboard. Please try again.',
        ),
      );
    }
  }
}
