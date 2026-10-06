import 'package:get_it/get_it.dart';
import 'package:shiftly/core/di/service_locator.dart';

abstract final class DependencyDisposal {
  static Future<void> reset({GetIt? locator}) =>
      (locator ?? getIt).reset(dispose: true);
}
