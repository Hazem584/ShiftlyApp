"""Print allowlisted build diagnostics, never raw verbose build output."""

import re
import shlex
import sys
from pathlib import Path


def summarize(log):
    lines = log.splitlines()
    output = ["Release build failed. Raw verbose output is private."]
    # Only fixed known messages are emitted, not adjacent source/config text.
    for marker in (
        "Null check operator used on a null value",
        "Target kernel_snapshot_program failed",
        ":app:compileFlutterBuildRelease",
    ):
        if marker in log:
            output.append(marker)

    # A frontend invocation only proves the compiler was started. Failure can
    # occur afterwards in AOT, assets/fonts, native hooks, or Gradle. Emit fixed
    # labels for observed signatures, never the exception's arbitrary message.
    signatures = {
        "non-constant instances of IconData": "Non-constant IconData prevents icon tree shaking.",
        "Font subsetting failed": "Font subsetting failed.",
        "The font-subset utility is missing": "The font-subset utility is missing.",
        "Unable to find asset": "An asset referenced by the build could not be found.",
        "No file or variants found for asset": "An asset referenced by pubspec could not be found.",
        "Failed to build native assets": "Native asset compilation failed.",
        "Failed to run build hooks": "Native build hooks failed.",
        "OutOfMemoryError": "Java reported OutOfMemoryError.",
        "Out of memory": "A tool reported out of memory.",
        "No space left on device": "A tool reported no space left on device.",
        "Gradle build daemon disappeared unexpectedly": "The Gradle daemon disappeared unexpectedly.",
        "Release signing requires": "Required release signing environment values are missing.",
        "Release keystore file is missing": "The release keystore file is missing.",
        "keystore password was incorrect": "The keystore password was rejected.",
        "Cannot recover key": "The signing key could not be recovered.",
        "Android resource linking failed": "Android resource linking failed.",
        "Could not resolve all files": "Gradle dependency resolution failed.",
    }
    output.extend(message for signature, message in signatures.items() if signature in log)
    # Only SDK-owned target/task names can cross the private-log boundary.
    targets = (
        "kernel_snapshot_program", "aot_android_asset_bundle", "android_aot_bundle",
        "android_aot_release_android_arm", "android_aot_release_android_arm64",
        "android_aot_release_android_x64", "release_android_application",
        "build_hooks", "link_hooks", "install_code_assets",
    )
    for target in targets:
        if re.search(r"\bTarget " + re.escape(target) + r" failed\b", log):
            message = "Failed Flutter target: " + target
            output.append(message)
    for task in (
        "compileFlutterBuildRelease", "validateSigningRelease", "packageRelease",
        "processReleaseResources", "mergeReleaseResources", "mergeReleaseAssets",
        "minifyReleaseWithR8", "assembleRelease",
    ):
        if re.search(r"Execution failed for task ['\"]:app:" + task + r"['\"]", log):
            output.append("Failed Gradle task: :app:" + task)
    for pattern, label in (
        (r"AOT snapshotter exited with code (-?\d{1,3})\b", "AOT snapshotter exit code"),
        (r"Font subsetting failed with exit code (-?\d{1,3})\b", "Font subset exit code"),
        (r"finished with non-zero exit value (-?\d{1,3})\b", "Gradle subprocess exit code"),
    ):
        for code in dict.fromkeys(re.findall(pattern, log)):
            output.append(label + ": " + code)
    exceptions = (
        "PathNotFoundException", "FileSystemException", "ProcessException",
        "IconTreeShakerException", "ToolExit", "CompilationError", "FormatException",
    )
    for exception in exceptions:
        if re.search(r"\b" + exception + r"\b", log):
            output.append("Observed exception type: " + exception)

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
    if invocations:
        output.append("A frontend invocation does not establish which build stage failed.")
    if not invocations:
        output.append("No frontend invocation found in verbose output.")

    # Extract compiler/tool package frames only; omit file:// paths and app contents.
    frames = re.findall(
        r"#\d+\s+[A-Za-z0-9_.$<> ]+\(package:"
        r"(?:front_end|frontend_server|kernel|vm|flutter_tools)/[A-Za-z0-9_./-]+\.dart:\d+(?::\d+)?\)",
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
