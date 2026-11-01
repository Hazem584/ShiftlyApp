import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/cubit/work_feed_cubit.dart';

void main() {
  test('canonical mutation success stays successful when its follow-up refresh fails', () async {
    var reads = 0, writes = 0;
    final cubit = WorkFeedCubit<String>((_) async {
      if (++reads > 1) throw const ApiException(message: 'Refresh unavailable');
      return const WorkPage(['request'], 1);
    });
    addTearDown(cubit.close);
    await cubit.load();
    final saved = await cubit.mutate('request', () async {
      writes++;
    });
    expect(saved, isTrue);
    expect(writes, 1);
    expect(cubit.state.items, ['request']);
    expect(cubit.state.error, 'Refresh unavailable');
  });

  test(
    'duplicate review stays blocked through the follow-up refresh',
    () async {
      final operation = Completer<void>();
      final refresh = Completer<WorkPage<String>>();
      var reads = 0, writes = 0;
      final cubit = WorkFeedCubit<String>((_) async {
        if (++reads == 1) return const WorkPage(['request'], 1);
        return await refresh.future;
      });
      addTearDown(cubit.close);
      await cubit.load();
      final first = cubit.mutate('request', () {
        writes++;
        return operation.future;
      });
      expect(
        await cubit.mutate('request', () async {
          writes++;
        }),
        isFalse,
      );
      operation.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.loading, isTrue);
      expect(
        await cubit.mutate('request', () async {
          writes++;
        }),
        isFalse,
      );
      refresh.complete(const WorkPage([], 0));
      expect(await first, isTrue);
      expect(writes, 1);
    },
  );

  test('a disposed workspace feed never starts another mutation', () async {
    var writes = 0;
    final cubit = WorkFeedCubit<String>((_) async => const WorkPage([], 0));
    await cubit.close();
    expect(
      await cubit.mutate('request', () async {
        writes++;
      }),
      isFalse,
    );
    expect(writes, 0);
  });
}
