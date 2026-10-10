plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep previews/builds without Firebase configuration usable.
if (file("google-services.json").isFile) {
    apply(plugin = "com.google.gms.google-services")
}

// Passwords stay in the process environment; no key.properties is generated in CI.
val releaseSigningValues = listOf(
    "ANDROID_KEYSTORE_PATH", "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD",
).associateWith { System.getenv(it)?.takeIf { value -> value.isNotBlank() } }
val hasReleaseSigning = releaseSigningValues.values.all { it != null }
val isReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (isReleaseTask || System.getenv("SHIFTLY_CI_RELEASE") == "true") {
    require(hasReleaseSigning) {
        "Release signing requires ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, " +
            "ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD. Debug signing is not allowed."
    }
    require(file(releaseSigningValues.getValue("ANDROID_KEYSTORE_PATH")!!).isFile) {
        "Release keystore file is missing."
    }
}

android {
    namespace = "com.example.shiftly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.shiftly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseSigningValues.getValue("ANDROID_KEYSTORE_PATH")!!)
                storePassword = releaseSigningValues.getValue("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = releaseSigningValues.getValue("ANDROID_KEY_ALIAS")
                keyPassword = releaseSigningValues.getValue("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
