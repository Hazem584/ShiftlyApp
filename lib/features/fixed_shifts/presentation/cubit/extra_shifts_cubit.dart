import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../../data/confirmed_mutation_rejection.dart';
import '../../data/extra_authorization.dart';
import '../../data/extra_shift_intent.dart';
import '../../data/extra_shift_repository.dart';
import 'extra_shifts_state.dart';

class ExtraShiftsCubit extends Cubit<ExtraShiftsState> {
  ExtraShiftsCubit(this.repository, {this.onChanged})
    : super(const ExtraShiftsState());
  final ExtraShiftRepository repository;
  final FutureOr<void> Function()? onChanged;
  FeatureSessionScope? _scope;
  String? _employeeId;
  int _generation = 0, _request = 0;
  bool _busy = false;
  int _mutation = 0;
  int? _owner;
  bool _valid(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;
  bool _owns(FeatureSessionScope scope, int generation, int owner) =>
      _valid(scope, generation) && _owner == owner;

  int _beginMutation() {
    _busy = true;
    _request++;
    return _owner = ++_mutation;
  }

  void _release(FeatureSessionScope scope, int generation, int owner) {
    if (!_owns(scope, generation, owner)) {
      return;
    }
    _owner = null;
    _busy = false;
    emit(
      ExtraShiftsState(
        loading: state.loading,
        page: state.page,
        intent: state.intent,
        canonical: state.canonical,
        recoveryBlocked: state.recoveryBlocked,
        failure: state.failure,
      ),
    );
  }

  void bind(FeatureSessionScope? scope, String employeeId) {
    final valid = scope?.isManager == true ? scope : null;
    if (_scope == valid && _employeeId == employeeId) {
      return;
    }
    _scope = valid;
    _employeeId = employeeId;
    _generation++;
    _request++;
    _busy = false;
    _owner = null;
    emit(const ExtraShiftsState());
    if (valid != null) {
      unawaited(load());
    }
  }

  Failure _failure(Object error, String fallback) =>
      error is ApiException ? error.toFailure() : Failure(message: fallback);
  Future<void> load({int page = 1}) => _load(page: page);

  Future<void> _load({int page = 1, int? owner}) async {
    final scope = _scope;
    final employee = _employeeId;
    if (scope == null || employee == null || (_busy && owner != _owner)) {
      return;
    }
    final generation = _generation, request = ++_request;
    final previous = state;
    emit(
      ExtraShiftsState(
        busy: _busy,
        loading: true,
        page: previous.page,
        canonical: previous.canonical,
        intent: previous.intent,
      ),
    );
    try {
      final raw = await repository.readExtraIntent(scope);
      final intent = raw == null ? null : ExtraShiftIntent.decode(raw);
      if (!_valid(scope, generation) || request != _request) {
        return;
      }
      emit(
        ExtraShiftsState(
          busy: _busy,
          loading: true,
          page: previous.page,
          intent: intent,
          canonical: previous.canonical,
        ),
      );
      final result = await repository.listExtras(
        scope.workspaceId,
        employee,
        page: page,
      );
      if (!_valid(scope, generation) || request != _request) {
        return;
      }
      if (result.data.any(
        (v) =>
            v.fields['workspaceId'] != scope.workspaceId ||
            v.fields['employeeMembershipId'] != employee,
      )) {
        throw const FormatException('Cross-scope extra response');
      }
      emit(
        ExtraShiftsState(
          busy: _busy,
          loading: false,
          page: result,
          intent: intent,
          recoveryBlocked: intent != null,
          canonical: previous.canonical,
        ),
      );
    } catch (error) {
      if (_valid(scope, generation) && request == _request) {
        emit(
          ExtraShiftsState(
            busy: _busy,
            loading: false,
            page: previous.page,
            intent: state.intent,
            canonical: previous.canonical,
            failure: _failure(
              error,
              'Unable to load extras or saved recovery. Retry before changing extras.',
            ),
          ),
        );
      }
    }
  }

  Future<bool> create(
    Map<String, Object?> payload, {
    required bool actual,
  }) async {
    final scope = _scope, employee = _employeeId;
    if (scope == null ||
        employee == null ||
        _busy ||
        state.loading ||
        state.recoveryBlocked) {
      return false;
    }
    final allowed = {
      'shiftTemplateId',
      'operationalDate',
      'reason',
      'explanation',
      if (actual) 'actualClockInAt',
      if (actual) 'actualClockOutAt',
    };
    if (payload.keys.any((key) => !allowed.contains(key)) ||
        payload['explanation'] is! String ||
        payload['shiftTemplateId'] is! String ||
        payload['operationalDate'] is! String ||
        !const {
          'COVERED_EMPLOYEE',
          'ADDITIONAL_SHIFT',
          'APPROVED_OVERTIME',
          'EMERGENCY_SUPPORT',
          'HIGH_WORKLOAD_SUPPORT',
          'OTHER',
        }.contains(payload['reason'])) {
      return false;
    }
    if (actual) {
      final start = DateTime.tryParse(
            payload['actualClockInAt'] as String? ?? '',
          ),
          end = DateTime.tryParse(payload['actualClockOutAt'] as String? ?? '');
      if (start == null ||
          end == null ||
          !end.isAfter(start) ||
          end.isAfter(DateTime.now().toUtc())) {
        return false;
      }
    }
    final normalized = Map<String, Object?>.from(payload);
    normalized['explanation'] = (normalized['explanation'] as String)
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    normalized['clientAuthorizationId'] = const Uuid().v4();
    return _submit(
      scope,
      ExtraShiftIntent(
        membershipId: employee,
        actual: actual,
        payload: normalized,
      ),
    );
  }

  Future<bool> recover() async {
    final scope = _scope, intent = state.intent;
    if (scope == null || intent == null || _busy) {
      return false;
    }
    return _submit(scope, intent);
  }

  Future<bool> _submit(
    FeatureSessionScope scope,
    ExtraShiftIntent intent,
  ) async {
    final owner = _beginMutation();
    final generation = _generation;
    emit(
      ExtraShiftsState(
        loading: false,
        busy: true,
        intent: intent,
        page: state.page,
        canonical: state.canonical,
      ),
    );
    try {
      await repository.saveExtraIntent(scope, intent.encode());
      if (!_owns(scope, generation, owner)) {
        return false;
      }
      final canonical = await repository.createExtra(
        scope.workspaceId,
        intent.membershipId,
        intent.payload,
        actual: intent.actual,
      );
      if (!_owns(scope, generation, owner)) {
        return false;
      }
      if (!const {
            'AUTHORIZED',
            'CONSUMED',
            'REVOKED',
          }.contains(canonical.status) ||
          canonical.fields['workspaceId'] != scope.workspaceId ||
          canonical.fields['employeeMembershipId'] != intent.membershipId ||
          canonical.fields['createdByMembershipId'] != scope.membershipId ||
          canonical.fields['clientAuthorizationId'] !=
              intent.payload['clientAuthorizationId'] ||
          canonical.fields['shiftTemplateId'] !=
              intent.payload['shiftTemplateId'] ||
          canonical.operationalDate != intent.payload['operationalDate'] ||
          canonical.fields['reason'] != intent.payload['reason'] ||
          canonical.fields['explanation'] != intent.payload['explanation'] ||
          (intent.actual && canonical.status != 'CONSUMED')) {
        throw const FormatException('Invalid extra response');
      }
      if (intent.actual) {
        final attendance = canonical.fields['attendance'] as List;
        if (attendance.length != 1 || attendance.first is! Map) {
          throw const FormatException('Missing canonical attendance');
        }
        final linked = attendance.first as Map;
        if (linked['extraAuthorizationId'] != canonical.id ||
            linked['enteredByMembershipId'] != scope.membershipId ||
            linked['occurrenceKind'] != 'EXTRA' ||
            linked['reviewStatus'] != 'APPROVED' ||
            DateTime.tryParse(
                  canonical.fields['actualClockInAt'] as String? ?? '',
                ) !=
                DateTime.parse(intent.payload['actualClockInAt'] as String) ||
            DateTime.tryParse(
                  canonical.fields['actualClockOutAt'] as String? ?? '',
                ) !=
                DateTime.parse(intent.payload['actualClockOutAt'] as String)) {
          throw const FormatException('Invalid manager attendance audit');
        }
      }
      emit(
        ExtraShiftsState(
          busy: true,
          loading: false,
          page: state.page,
          canonical: canonical,
          intent: intent,
        ),
      );
      var cleared = false;
      try {
        await repository.clearExtraIntent(scope, intent.encode());
        cleared = true;
      } catch (_) {}
      if (!_owns(scope, generation, owner)) {
        return true;
      }
      emit(
        ExtraShiftsState(
          busy: true,
          loading: false,
          page: state.page,
          canonical: canonical,
          intent: cleared ? null : intent,
          recoveryBlocked: !cleared,
        ),
      );
      try {
        await onChanged?.call();
      } catch (_) {}
      if (_owns(scope, generation, owner)) {
        await _load(page: state.page?.pagination.page ?? 1, owner: owner);
      }
      return true;
    } catch (error) {
      if (!_owns(scope, generation, owner)) {
        return false;
      }
      var cleared = false;
      if (confirmedMutationRejection(error)) {
        try {
          await repository.clearExtraIntent(scope, intent.encode());
          cleared = true;
        } catch (_) {}
      }
      if (_owns(scope, generation, owner)) {
        emit(
          ExtraShiftsState(
            busy: true,
            loading: false,
            page: state.page,
            intent: cleared ? null : intent,
            canonical: state.canonical,
            recoveryBlocked: !cleared,
            failure: _failure(
              error,
              'Operation may have succeeded. Recover the saved request before creating another extra.',
            ),
          ),
        );
      }
      return false;
    } finally {
      _release(scope, generation, owner);
    }
  }

  Future<bool> revoke(ExtraAuthorization value) async {
    final scope = _scope, employee = _employeeId;
    if (scope == null ||
        employee == null ||
        _busy ||
        state.loading ||
        state.recoveryBlocked ||
        !value.canRevoke ||
        value.fields['employeeMembershipId'] != employee ||
        value.fields['workspaceId'] != scope.workspaceId) {
      return false;
    }
    final owner = _beginMutation();
    final generation = _generation;
    emit(
      ExtraShiftsState(
        loading: false,
        busy: true,
        page: state.page,
        canonical: state.canonical,
        recoveryBlocked: false,
      ),
    );
    try {
      final canonical = await repository.revokeExtra(
        scope.workspaceId,
        employee,
        value.id,
      );
      if (!_owns(scope, generation, owner)) {
        return false;
      }
      if (canonical.id != value.id ||
          canonical.status != 'REVOKED' ||
          canonical.fields['workspaceId'] != scope.workspaceId ||
          canonical.fields['employeeMembershipId'] != employee) {
        throw const FormatException('Invalid revocation response');
      }
      emit(
        ExtraShiftsState(
          busy: true,
          loading: false,
          canonical: canonical,
          page: state.page,
          recoveryBlocked: false,
        ),
      );
      try {
        await onChanged?.call();
      } catch (_) {}
      if (_owns(scope, generation, owner)) {
        await _load(page: state.page?.pagination.page ?? 1, owner: owner);
      }
      return true;
    } catch (error) {
      if (_owns(scope, generation, owner)) {
        emit(
          ExtraShiftsState(
            busy: true,
            loading: false,
            page: state.page,
            canonical: state.canonical,
            failure: _failure(
              error,
              'Unable to confirm revocation. Refresh its status before retrying.',
            ),
          ),
        );
      }
      return false;
    } finally {
      _release(scope, generation, owner);
    }
  }
}
