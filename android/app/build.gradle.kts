import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
    true
} else {
    false
}

android {
    namespace = "com.clustudy.clustudy"
    compileSdk = flutter.compileSdkVersion
    // Target the latest stable NDK with 16 KB page support (Android 15 requirement).
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.clustudy.clustudy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        // 16KB page size support for Android 15+ (required by Google Play)
        // Keep JNI libs uncompressed so Play can align them for 16 KB page sizes.
        // This is required for Google Play to automatically align native libraries for 16KB page sizes.
        jniLibs {
            useLegacyPackaging = false
        }
        // Ensure native libraries are not compressed for 16KB alignment
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    // Explicitly enable 16KB page size support
    // AGP 8.5.1+ automatically handles this, but we ensure it's enabled
    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val storeFilePath = keystoreProperties["storeFile"] as String?
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.2")
    implementation("androidx.core:core-ktx:1.13.1")
}
