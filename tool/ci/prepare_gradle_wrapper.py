"""Prepare ignored Gradle launcher files using the installed, verified Flutter SDK."""

import os
import shutil
import stat
from pathlib import Path

WRAPPER_FILES = ("gradlew", "gradlew.bat", "gradle/wrapper/gradle-wrapper.jar")


def prepare(project_root, flutter_root):
    android = Path(project_root).resolve() / "android"
    source = Path(flutter_root).resolve() / "bin/cache/artifacts/gradle_wrapper"
    if not (android / "gradle/wrapper/gradle-wrapper.properties").is_file():
        raise RuntimeError("The project's Gradle wrapper version configuration is missing.")
    # Check the complete SDK artifact before copying any files.
    if any(not (source / name).is_file() for name in WRAPPER_FILES):
        raise RuntimeError("Flutter Gradle wrapper artifacts are missing. Run flutter precache --android first.")
    for name in WRAPPER_FILES:
        target = android / name
        if target.is_symlink() or not target.resolve().is_relative_to(android.resolve()):
            raise RuntimeError("Gradle wrapper destination must stay inside the Android project.")
    for name in WRAPPER_FILES:
        target = android / name
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / name, target)
    launcher = android / "gradlew"
    if os.name != "nt":
        launcher.chmod(launcher.stat().st_mode | stat.S_IXUSR)
    # Keep the checked-in Gradle version and any existing custom launchers intact.
    print("Gradle wrapper launchers and JAR are ready; project Gradle version preserved.")


def main():
    flutter = shutil.which("flutter")
    if not flutter:
        raise SystemExit("Flutter must be installed and available on PATH before preparing Gradle.")
    try:
        prepare(Path.cwd(), Path(flutter).resolve().parent.parent)
    except (OSError, RuntimeError) as error:
        if isinstance(error, RuntimeError):
            raise SystemExit(str(error)) from None
        raise SystemExit("Could not prepare the Gradle wrapper files.") from None


if __name__ == "__main__":
    main()
