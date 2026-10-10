import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Never fall back to the debug key for a production release.
val releaseKeyFile = rootProject.file("key.properties")
val releaseKeys = Properties()
if (releaseKeyFile.exists()) {
    FileInputStream(releaseKeyFile).use { releaseKeys.load(it) }
}
val hasReleaseKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseKeys.getProperty(it).isNullOrBlank() }

android {
    namespace = "com.example.akka_tutor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.auxiumsoft.arivora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeys) {
            create("upload") {
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeys) signingConfig = signingConfigs.getByName("upload")
        }
    }
}

flutter {
    source = "../.."
}

val validateUploadSigning by tasks.registering {
    doLast {
        check(hasReleaseKeys) {
            "Release signing is missing. Configure android/key.properties using key.properties.example. Debug signing is not permitted for release builds."
        }
        check(rootProject.file(releaseKeys.getProperty("storeFile")).isFile) {
            "The upload keystore configured in android/key.properties does not exist."
        }
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(validateUploadSigning)
}
