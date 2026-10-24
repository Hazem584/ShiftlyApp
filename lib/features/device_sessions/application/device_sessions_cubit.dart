import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class DeviceSessionsState {
  const DeviceSessionsState({
    this.items = const [],
    this.loading = false,
    this.busy = false,
    this.hasNext = false,
    this.error,
  });
  final List<DeviceSession> items;
  final bool loading;
  final bool busy;
  final bool hasNext;
  final String? error;
}

class DeviceSessionsCubit extends Cubit<DeviceSessionsState> {
  DeviceSessionsCubit(this.repository) : super(const DeviceSessionsState());
  final DeviceSessionsRepository repository;
  int _page = 0;
  int _generation = 0;
  Future<void> load({bool more = false}) async {
    if (state.loading || state.busy || (more && !state.hasNext)) return;
    final generation = ++_generation;
    final previous = state;
    emit(
      DeviceSessionsState(
        items: previous.items,
        hasNext: previous.hasNext,
        loading: true,
      ),
    );
    try {
      final page = more ? _page + 1 : 1;
      final result = await repository.load(page: page);
      if (isClosed || generation != _generation) return;
      _page = page;
      emit(
        DeviceSessionsState(
          items: more ? [...previous.items, ...result.items] : result.items,
          hasNext: result.hasNext,
        ),
      );
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          DeviceSessionsState(
            items: previous.items,
            hasNext: previous.hasNext,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
    }
  }

  Future<bool?> revoke(DeviceSession? target) async {
    if (state.busy || state.loading) return null;
    final previous = state;
    ++_generation;
    emit(
      DeviceSessionsState(
        items: previous.items,
        hasNext: previous.hasNext,
        busy: true,
      ),
    );
    try {
      final current = target == null
          ? await _revokeAll()
          : await repository.revoke(target.id);
      if (isClosed) return current;
      emit(
        DeviceSessionsState(
          items: current
              ? const []
              : previous.items.where((item) => item.id != target?.id).toList(),
          hasNext: previous.hasNext,
        ),
      );
      if (!current) await load();
      return current;
    } catch (error) {
      if (!isClosed) {
        emit(
          DeviceSessionsState(
            items: previous.items,
            hasNext: previous.hasNext,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
      return null;
    }
  }

  Future<bool> _revokeAll() async {
    await repository.revokeAll();
    return true;
  }
}
