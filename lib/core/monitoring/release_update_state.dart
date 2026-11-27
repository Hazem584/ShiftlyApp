typedef ReleaseUpdateState = ({
  Map<String, dynamic>? visibleRelease,
  bool initial,
  bool launching,
  bool launchFailed,
  bool attemptedUpdate,
});

const ReleaseUpdateState initialReleaseUpdateState = (
  visibleRelease: null,
  initial: true,
  launching: false,
  launchFailed: false,
  attemptedUpdate: false,
);
