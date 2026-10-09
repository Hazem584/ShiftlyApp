import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_mutation_intent.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_points_repository.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:uuid/uuid.dart';

class ManagerPerformanceCubit extends Cubit<ManagerPerformanceState> {
  ManagerPerformanceCubit(this.repository, this.storage, {this.onChanged})
    : super(const ManagerPerformanceState());
  final ManagerPointsRepository repository;
  final ManagerIntentStorage storage;
  final void Function()? onChanged;
  final Map<String, int> _requests = {};
  final Set<String> _pendingRefresh = {};
  @override
  Future<void> close() {
    _epoch++;
    repository.bindSession(null);
    return super.close();
  }

  int _epoch = 0;
  FeatureSessionScope? _deniedScope;
  Future<void>? _mutation;
  static String key(String resource, String? target) =>
      '${target ?? 'workspace'}:$resource';

  void bindSession(FeatureSessionScope? scope) {
    final valid = scope?.isManager == true && scope != _deniedScope
        ? scope
        : null;
    if (state.scope == valid) {
      return;
    }
    _epoch++;
    repository.bindSession(valid);
    _requests.clear();
    _pendingRefresh.clear();
    emit(ManagerPerformanceState(scope: valid, restoring: valid != null));
    if (valid != null) {
      unawaited(_restore(valid, _epoch));
    }
  }

  bool _current(FeatureSessionScope scope, int epoch) =>
      !isClosed && epoch == _epoch && state.scope == scope;
  bool _accessLost(Object error, FeatureSessionScope scope, int epoch) {
    final failure = ApiErrorParser.parse(error);
    if (_current(scope, epoch) &&
        ((failure.statusCode == 403 &&
                {
                  'WORKSPACE_ACCESS_DENIED',
                  'MANAGER_ROLE_REQUIRED',
                }.contains(failure.code)) ||
            (failure.statusCode == 404 &&
                failure.code == 'WORKSPACE_NOT_FOUND'))) {
      _deniedScope = scope;
      bindSession(null);
      return true;
    }
    return false;
  }

  void _update({
    Map<String, ManagerResourceState>? resources,
    ManagerMutationIntent? intent,
    bool clearIntent = false,
    bool? restoring,
    bool? busy,
    String? message,
  }) {
    if (isClosed) {
      return;
    }
    emit(
      ManagerPerformanceState(
        scope: state.scope,
        resources: resources ?? state.resources,
        intent: clearIntent ? null : intent ?? state.intent,
        restoring: restoring ?? state.restoring,
        busy: busy ?? state.busy,
        message: message,
      ),
    );
  }

  Future<void> _restore(FeatureSessionScope scope, int epoch) async {
    try {
      await _mutation;
      final saved = await storage.read(scope);
      final intent = saved == null ? null : ManagerMutationIntent.decode(saved);
      if (_current(scope, epoch)) {
        _update(
          intent: intent,
          restoring: false,
          message: intent == null ? null : 'A saved operation needs recovery. No request was submitted automatically.',
        );
      }
    } catch (_) {
      if (_current(scope, epoch)) {
        _update(
          message: 'Saved operations could not be read. Reopen this workspace before making changes.',
        );
      }
    }
  }

  Future<void> load(
    String resource, {
    String? target,
    bool object = false,
    bool more = false,
    Map<String, Object?> query = const {},
  }) async {
    final scope = state.scope;
    if (scope == null) {
      return;
    }
    final epoch = _epoch;
    final resourceKey = key(resource, target);
    final before = state.resources[resourceKey] ?? const ManagerResourceState();
    final sameFilter = mapEquals(before.query, query);
    if (before.loading && sameFilter) {
      return;
    }
    if (more && (!sameFilter || !before.hasMore)) {
      return;
    }
    final request = (_requests[resourceKey] ?? 0) + 1;
    _requests[resourceKey] = request;
    final retained = sameFilter ? before : const ManagerResourceState();
    final page = more ? retained.page + 1 : 1;
    _put(
      resourceKey,
      ManagerResourceState(
        records: retained.records,
        object: retained.object,
        loading: true,
        page: retained.page,
        hasMore: retained.hasMore,
        query: query,
      ),
    );
    try {
      final result = object
          ? await repository.get(scope.workspaceId, resource, target: target)
          : null;
      final paginated = {'summary', 'history', 'disputes'}.contains(resource);
      final list = object
          ? null
          : await repository.list(
              scope.workspaceId,
              resource,
              target: target,
              query: {
                ...query,
                if (paginated) ...{'page': page, 'limit': 20},
              },
            );
      if (!_current(scope, epoch) || _requests[resourceKey] != request) {
        return;
      }
      if (list?.pagination != null && list!.pagination!.page != page) {
        throw const FormatException('Unexpected page');
      }
      final dedup = {
        if (more)
          for (final record in retained.records) record.id: record,
        for (final record in list?.records ?? []) record.id: record,
      };
      _put(
        resourceKey,
        ManagerResourceState(
          records: List.unmodifiable(dedup.values),
          object: result,
          page: page,
          hasMore:
              list?.pagination != null && page < list!.pagination!.totalPages,
          query: query,
        ),
      );
    } catch (error) {
      if (_accessLost(error, scope, epoch)) {
        return;
      }
      if (_current(scope, epoch) && _requests[resourceKey] == request) {
        _put(
          resourceKey,
          ManagerResourceState(
            records: retained.records,
            object: retained.object,
            page: retained.page,
            hasMore: retained.hasMore,
            query: query,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
    } finally {
      if (_current(scope, epoch) &&
          _requests[resourceKey] == request &&
          _pendingRefresh.remove(resourceKey)) {
        unawaited(load(resource, target: target, object: object, query: query));
      }
    }
  }

  void _put(String key, ManagerResourceState resource) => _update(
    resources: {...state.resources, key: resource},
    message: state.message,
  );

  void invalidate() {
    for (final entry in Map<String, ManagerResourceState>.from(
      state.resources,
    ).entries) {
      if (entry.value.loading) {
        _pendingRefresh.add(entry.key);
        continue;
      }
      final split = entry.key.indexOf(':');
      final target = entry.key.substring(0, split);
      final resource = entry.key.substring(split + 1);
      unawaited(
        load(
          resource,
          target: target == 'workspace' ? null : target,
          object: resource.isEmpty || resource.contains('/'),
          query: entry.value.query,
        ),
      );
    }
  }

  Future<void> submit(
    String resource,
    Map<String, Object?> payload, {
    String? target,
    String? uuidField,
    bool patch = false,
  }) {
    if (!state.canMutate) {
      return Future.value();
    }
    final normalized = {
      ...payload,
      for (final entry in payload.entries)
        if (entry.value is String) entry.key: (entry.value! as String).trim(),
    };
    // Dart 3.13.5's AOT frontend crashes on a null-aware map key whose
    // value invokes a const receiver. Keep UUID creation conditional without
    // triggering that lowering bug or the collection-if modernization lint.
    if (uuidField != null) {
      normalized[uuidField] = const Uuid().v4();
    }
    final intent = ManagerMutationIntent(
      resource: resource,
      target: target,
      payload: normalized,
      patch: patch,
    );
    _update(intent: intent, busy: true);
    return _mutation = _execute(intent, persist: true);
  }

  Future<void> recover() {
    final intent = state.intent;
    if (intent == null ||
        state.busy ||
        state.restoring ||
        state.scope == null) {
      return Future.value();
    }
    _update(busy: true);
    return _mutation = _execute(intent, persist: false);
  }

  Future<void> _execute(
    ManagerMutationIntent intent, {
    required bool persist,
  }) async {
    final scope = state.scope!;
    final epoch = _epoch;
    var success = false;
    var terminal = false;
    try {
      await storage.write(scope, intent.encode());
      if (!_current(scope, epoch)) {
        return;
      }
      if (!persist && !intent.hasUuid) {
        final confirmed = await _resolve(scope, intent);
        if (confirmed == null) {
          throw const ApiException(
            message: 'Outcome is unresolved. Read canonical records again before continuing.',
          );
        }
        success = confirmed;
        terminal = !confirmed;
      } else {
        await repository.mutate(
          scope.workspaceId,
          intent.resource,
          intent.payload,
          target: intent.target,
          patch: intent.patch,
        );
        success = true;
      }
    } catch (error) {
      if (_accessLost(error, scope, epoch)) {
        return;
      }
      final parsed = ApiErrorParser.parse(error);
      // These rejections occur after the original idempotency lookup.
      terminal =
          (intent.resource == 'policies' &&
              parsed.statusCode == 409 &&
              {
                'POINTS_POLICY_EFFECTIVE_DATE_IN_PAST',
                'POINTS_POLICY_CONFLICT',
              }.contains(parsed.code)) ||
          (intent.patch &&
              parsed.statusCode == 409 &&
              parsed.code == 'POINT_DISPUTE_ALREADY_REVIEWED') ||
          (intent.resource.endsWith('/reverse') &&
              parsed.statusCode == 409 &&
              {
                'EXTRA_EFFORT_ALREADY_REVERSED',
                'POINT_ADJUSTMENT_ALREADY_REVERSED',
              }.contains(parsed.code)) ||
          (intent.resource == 'adjustments' &&
              parsed.statusCode == 409 &&
              parsed.code == 'POINTS_BALANCE_INVARIANT_VIOLATION') ||
          (intent.resource == 'extra-effort' &&
              ((parsed.statusCode == 409 &&
                      parsed.code == 'POINTS_POLICY_DISABLED') ||
                  (parsed.statusCode == 400 &&
                      parsed.code == 'EXTRA_EFFORT_INVALID')));
      if (_current(scope, epoch)) {
        _update(message: parsed.message);
      }
    }
    if (success || terminal) {
      try {
        await storage.clear(scope, intent.encode());
        if (_current(scope, epoch)) {
          _update(
            clearIntent: true,
            message: success
                ? 'Change confirmed by the server.'
                : 'Canonical records confirm this operation cannot proceed.',
          );
        }
      } catch (_) {
        if (_current(scope, epoch)) {
          _update(
            message: success
                ? 'Change confirmed. Saved recovery could not be cleared; recover before another change.'
                : 'Rejection confirmed; saved recovery could not be cleared.',
          );
        }
      }
    }
    if (_current(scope, epoch)) {
      _update(busy: false, message: state.message);
      if (success) {
        onChanged?.call();
        final resources = Map<String, ManagerResourceState>.from(
          state.resources,
        );
        await Future.wait(
          resources.entries.map((entry) {
            final split = entry.key.indexOf(':');
            final target = entry.key.substring(0, split);
            return load(
              entry.key.substring(split + 1),
              target: target == 'workspace' ? null : target,
              object:
                  entry.key.substring(split + 1).isEmpty ||
                  entry.key.substring(split + 1).contains('/'),
              query: entry.value.query,
            );
          }),
        );
      }
    }
  }

  Future<bool?> _resolve(
    FeatureSessionScope scope,
    ManagerMutationIntent intent,
  ) async {
    if (intent.patch) {
      final record = await repository.get(
        scope.workspaceId,
        intent.resource.replaceFirst('/review', ''),
      );
      if (record['status'] == 'PENDING') {
        return null;
      }
      if (record['status'] == intent.payload['decision'] &&
          record['managerResponse'] == intent.payload['response'] &&
          record['reviewedByMembershipId'] == scope.membershipId) {
        return true;
      }
      return {'APPROVED', 'REJECTED', 'CANCELLED'}.contains(record['status'])
          ? false
          : null;
    }
    final policies = await repository.list(scope.workspaceId, 'policies');
    final date = intent.payload['effectiveFrom'];
    final matching = policies.records.where(
      (record) => record.fields['effectiveFrom'] == date,
    );
    if (matching.isEmpty) {
      return null;
    }
    final record = matching.first;
    return record.fields['createdByMembershipId'] == scope.membershipId &&
        intent.payload.entries.every(
          (entry) => record.fields[entry.key] == entry.value,
        );
  }
}
