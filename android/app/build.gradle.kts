import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ Correct plugin name for modern Gradle
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties file for release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.doc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ✅ Updated to use Java 17 for modern Android builds
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // ✅ Match the Java version (important for Gradle sync)
        jvmTarget = "17"
    }

    // ✅ Release signing configuration
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "upload"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String? ?: "upload-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.example.doc"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ Use release signing for production builds
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
