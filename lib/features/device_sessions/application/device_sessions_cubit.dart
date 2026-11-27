import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_state.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

export 'device_sessions_state.dart';

class DeviceSessionsCubit extends Cubit<DeviceSessionsState> {
  DeviceSessionsCubit(this.repository) : super(const DeviceSessionsState());
  final DeviceSessionsRepository repository;
  int _page = 0, _generation = 0;

  Future<void> load({bool more = false}) async {
    if (state.loading || state.busy || (more && !state.hasNext)) return;
    final gen = ++_generation, prev = state;
    emit(
      DeviceSessionsState(
        items: prev.items,
        hasNext: prev.hasNext,
        loading: true,
      ),
    );
    try {
      final page = more ? _page + 1 : 1;
      final res = await repository.load(page: page);
      if (isClosed || gen != _generation) return;
      _page = page;
      emit(
        DeviceSessionsState(
          items: more ? [...prev.items, ...res.items] : res.items,
          hasNext: res.hasNext,
        ),
      );
    } catch (e) {
      if (!isClosed && gen == _generation) _emitError(prev, e);
    }
  }

  Future<bool?> revoke(DeviceSession? target) async {
    if (state.busy || state.loading) return null;
    final prev = state;
    ++_generation;
    emit(
      DeviceSessionsState(items: prev.items, hasNext: prev.hasNext, busy: true),
    );
    try {
      final current = target == null
          ? await _revokeAll()
          : await repository.revoke(target.id);
      if (isClosed) return current;
      final remaining = current
          ? const <DeviceSession>[]
          : prev.items.where((i) => i.id != target?.id).toList();
      emit(DeviceSessionsState(items: remaining, hasNext: prev.hasNext));
      if (!current) await load();
      return current;
    } catch (e) {
      if (!isClosed) _emitError(prev, e);
      return null;
    }
  }

  void _emitError(DeviceSessionsState prev, Object error) => emit(
    DeviceSessionsState(
      items: prev.items,
      hasNext: prev.hasNext,
      error: ApiErrorParser.parse(error).message,
    ),
  );

  Future<bool> _revokeAll() async {
    await repository.revokeAll();
    return true;
  }
}
