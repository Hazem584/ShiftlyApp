"""Print allowlisted compiler diagnostics, never raw verbose build output."""

import re
import shlex
import sys
from pathlib import Path


def summarize(log):
    lines = log.splitlines()
    output = ["Release compilation failed. Raw verbose output is private."]
    # Only fixed known messages are emitted, not adjacent source/config text.
    for marker in (
        "Null check operator used on a null value",
        "Target kernel_snapshot_program failed",
        ":app:compileFlutterBuildRelease",
    ):
        if marker in log:
            output.append(marker)

    invocations = []
    for line in lines:
        if "frontend_server" not in line or ".snapshot" not in line:
            continue
        # Paths, positional arguments, -D values, encoded defines, and all
        # option values are withheld. Preserve only known compiler switches.
        command = line[line.find("frontend_server"):]
        try:
            tokens = shlex.split(command)
        except ValueError:
            continue
        safe_switches = {
            "--aot", "--tfa", "--no-tfa", "--track-widget-creation",
            "--no-track-widget-creation", "--link-platform", "--no-link-platform",
            "--embed-sources", "--no-embed-sources", "--incremental",
            "--no-incremental", "--target=flutter",
        }
        known_options = {
            "--sdk-root", "--packages", "--output-dill", "--depfile",
            "--initialize-from-dill", "--platform", "--target",
            "--verbosity", "--source", "--native-assets",
            "--enable-experiment", "--dart-define", "--dart-define-from-file",
        }
        redacted = ["<frontend_server.snapshot>"]
        for token in tokens[1:]:
            key = token.split("=", 1)[0]
            if token in safe_switches:
                redacted.append(token)
            elif token.startswith("-D"):
                redacted.append("-D<redacted>")
            elif key in known_options:
                redacted.append(key + "=<redacted>")
            else:
                redacted.append("<redacted>")
        summary = " ".join(redacted)
        if summary not in invocations:
            invocations.append(summary)
    output.extend("Frontend invocation (redacted): " + line for line in invocations[:3])
    if not invocations:
        output.append("No frontend invocation found in verbose output.")

    # Extract compiler package frames only; omit file:// paths and app contents.
    frames = re.findall(
        r"#\d+\s+[A-Za-z0-9_.$<> ]+\(package:"
        r"(?:front_end|frontend_server|kernel|vm)/[A-Za-z0-9_./-]+\.dart:\d+(?::\d+)?\)",
        log,
    )
    output.extend(dict.fromkeys(frames[:110]))
    locations = re.findall(
        r"(?<![A-Za-z0-9_/])lib/[A-Za-z0-9_./-]+\.dart:\d+:\d+", log
    )
    if locations:
        output.extend("Reported source location: " + location for location in sorted(set(locations))[:20])
    else:
        output.append("No app source location reported; the stack alone cannot identify the responsible expression.")
    output.append("Private build log is deleted by workflow cleanup; no log artifact is uploaded.")
    return "\n".join(output)


if __name__ == "__main__":
    print(summarize(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")))
