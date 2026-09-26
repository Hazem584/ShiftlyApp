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

class Failure {
  const Failure({
    required this.message,
    this.kind = FailureKind.unknown,
    this.requestId,
  });

  final String message;
  final FailureKind kind;
  final String? requestId;
}
