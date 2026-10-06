part of '../../failure.dart';

enum FailureKind {
  authentication,
  authorization,
  validation,
  network,
  timeout,
  cancelled,
  server,
  unknown,
}
