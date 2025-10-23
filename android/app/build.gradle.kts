plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")    // Firebase
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gallo.preventivi"
    compileSdk = flutter.compileSdkVersion

    // NDK richiesto dai plugin Firebase usati
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.gallo.preventivi"
        minSdk = 23                     // obbligatorio per cloud_firestore 6.x
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ok per debug
        }
    }
}

flutter {
    source = "../.."
}
