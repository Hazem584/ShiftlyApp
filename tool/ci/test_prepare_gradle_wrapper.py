"""Regression tests for a fresh checkout without ignored Gradle launchers."""

import contextlib
import io
import os
import stat
import tempfile
import unittest
from pathlib import Path

from prepare_gradle_wrapper import WRAPPER_FILES, prepare


class PrepareGradleWrapperTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="shiftly-wrapper-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project"
        self.sdk = self.root / "flutter"
        self.artifact = self.sdk / "bin/cache/artifacts/gradle_wrapper"
        self.properties = self.project / "android/gradle/wrapper/gradle-wrapper.properties"
        self.properties.parent.mkdir(parents=True)
        self.version = b"distributionUrl=https://services.gradle.org/distributions/gradle-9.3.1-all.zip\n"
        self.properties.write_bytes(self.version)
        for name in WRAPPER_FILES:
            file = self.artifact / name
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(("sdk fixture " + name).encode())

    def run_prepare(self):
        with contextlib.redirect_stdout(io.StringIO()):
            prepare(self.project, self.sdk)

    def test_fresh_checkout_gets_all_three_launcher_files(self):
        self.assertFalse((self.project / "android/gradlew").exists())
        self.run_prepare()
        for name in WRAPPER_FILES:
            self.assertEqual((self.project / "android" / name).read_bytes(),
                             (self.artifact / name).read_bytes())
        self.assertEqual(self.properties.read_bytes(), self.version)

    def test_existing_custom_files_are_preserved(self):
        for name in WRAPPER_FILES:
            file = self.project / "android" / name
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b"custom wrapper")
        self.run_prepare()
        self.run_prepare()
        for name in WRAPPER_FILES:
            self.assertEqual((self.project / "android" / name).read_bytes(), b"custom wrapper")
        self.assertEqual(self.properties.read_bytes(), self.version)

    def test_missing_sdk_artifact_fails_before_partial_copy(self):
        (self.artifact / "gradle/wrapper/gradle-wrapper.jar").unlink()
        with self.assertRaisesRegex(RuntimeError, "precache"):
            self.run_prepare()
        self.assertFalse((self.project / "android/gradlew").exists())

    def test_missing_project_version_is_not_silently_replaced(self):
        self.properties.unlink()
        with self.assertRaisesRegex(RuntimeError, "version configuration"):
            self.run_prepare()
        self.assertFalse(self.properties.exists())

    @unittest.skipIf(os.name == "nt", "Unix executable permissions")
    def test_unix_launcher_is_executable(self):
        self.run_prepare()
        mode = (self.project / "android/gradlew").stat().st_mode
        self.assertTrue(mode & stat.S_IXUSR)


if __name__ == "__main__":
    unittest.main()
