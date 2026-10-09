"""Regression fixtures for safe release-failure diagnostics; no real secrets."""

import unittest

from summarize_release_failure import summarize


class ReleaseFailureSummaryTest(unittest.TestCase):
    def test_heap_dump_option_is_not_an_oom_error(self):
        output = summarize(
            "Starting Gradle with -Xmx8G -XX:+HeapDumpOnOutOfMemoryError\n"
            "java.io.IOException: No space left on device"
        )
        self.assertNotIn("Java reported OutOfMemoryError", output)
        self.assertIn("A tool reported no space left on device.", output)

    def test_actual_java_oom_is_reported_without_private_details(self):
        output = summarize(
            "java.lang.OutOfMemoryError: Java heap space fixture-secret"
        )
        self.assertIn("Java reported OutOfMemoryError.", output)
        self.assertNotIn("fixture-secret", output)

    def test_frontend_invocation_does_not_imply_compiler_crash(self):
        output = summarize(
            "frontend_server.snapshot --aot --tfa --target=flutter "
            "-DAPI_TOKEN=fixture-secret --packages=/private/packages.json\n"
            "Execution failed for task ':app:compileFlutterBuildRelease'."
        )
        self.assertIn("Failed Gradle task: :app:compileFlutterBuildRelease", output)
        self.assertIn("does not establish which build stage failed", output)
        self.assertNotIn("Null check operator", output)
        self.assertNotIn("fixture-secret", output)
        self.assertNotIn("/private", output)

    def test_asset_failure_after_frontend_keeps_stage_and_exception(self):
        output = summarize(
            "frontend_server.snapshot --aot\n"
            "Target aot_android_asset_bundle failed: PathNotFoundException: "
            "Cannot open file, path = '/private/fixture-secret'\n"
            "#0 AndroidAssetBundle.build "
            "(package:flutter_tools/src/build_system/targets/android.dart:90:4)"
        )
        self.assertIn("Failed Flutter target: aot_android_asset_bundle", output)
        self.assertIn("Observed exception type: PathNotFoundException", output)
        self.assertIn("AndroidAssetBundle.build", output)
        self.assertNotIn("fixture-secret", output)

    def test_font_failure_has_safe_reason_and_exit_code(self):
        output = summarize(
            "IconTreeShakerException: It has non-constant instances of IconData "
            "at the following locations: fixture-secret\n"
            "Font subsetting failed with exit code 255."
        )
        self.assertIn("Non-constant IconData prevents icon tree shaking.", output)
        self.assertIn("Font subset exit code: 255", output)
        self.assertNotIn("fixture-secret", output)

    def test_aot_failure_and_gradle_process_exit_are_preserved(self):
        output = summarize(
            "Target android_aot_release_android_arm64 failed: "
            "Exception: AOT snapshotter exited with code -9\n"
            "Process 'command /private/fixture-secret' "
            "finished with non-zero exit value 137"
        )
        self.assertIn("Failed Flutter target: android_aot_release_android_arm64", output)
        self.assertIn("AOT snapshotter exit code: -9", output)
        self.assertIn("Gradle subprocess exit code: 137", output)
        self.assertNotIn("fixture-secret", output)

    def test_original_compiler_failure_remains_visible(self):
        output = summarize(
            "Null check operator used on a null value\n"
            "Target kernel_snapshot_program failed\n"
            "#0 ConstantEvaluator._recordConstructorCoverage "
            "(package:front_end/src/kernel/constant_evaluator.dart:3082:7)\n"
            "lib/example.dart:10:2"
        )
        self.assertIn("Null check operator used on a null value", output)
        self.assertIn("ConstantEvaluator._recordConstructorCoverage", output)
        self.assertIn("Reported source location: lib/example.dart:10:2", output)

    def test_unknown_messages_arguments_and_task_names_are_withheld(self):
        output = summarize(
            "frontend_server.snapshot --aot --dart-defines=Zml4dHVyZS1zZWNyZXQ= "
            "--dart-define API_TOKEN=fixture-secret --unknown=fixture-secret\n"
            "Execution failed for task ':app:fixture-secret'.\n"
            "Target fixture-secret failed\n"
            "ProcessException: https://example.invalid/?token=fixture-secret\n"
            "Error: Authorization: Bearer fixture-secret"
        )
        self.assertIn("Observed exception type: ProcessException", output)
        for private_value in ("fixture-secret", "Zml4dHVyZS1zZWNyZXQ=", "https://"):
            self.assertNotIn(private_value, output)


if __name__ == "__main__":
    unittest.main()
