plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.turnpiece.temphist"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.turnpiece.temphist"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // flutter.versionCode reads the build number from pubspec.yaml. This project
        // uses a YYYYMMDDHHMM timestamp format (e.g. 202605232043) which exceeds
        // Android's Int32 versionCode ceiling (~2.1B). Derive a code from the version
        // name components instead: major * 10000 + minor * 100 + patch (e.g. 10210).
        val versionParts = flutter.versionName.split(".")
        versionCode = (versionParts.getOrNull(0)?.toIntOrNull() ?: 1) * 10000 +
                      (versionParts.getOrNull(1)?.toIntOrNull() ?: 0) * 100 +
                      (versionParts.getOrNull(2)?.toIntOrNull() ?: 0)
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
