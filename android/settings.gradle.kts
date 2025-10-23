pluginManagement {
    // legge flutter.sdk da local.properties
    val localProps = java.util.Properties().apply {
        val f = java.io.File(rootDir, "local.properties")
        require(f.exists()) { "local.properties non trovato in ${rootDir.absolutePath}" }
        java.io.FileInputStream(f).use { this.load(it) }
    }
    val flutterSdkPath = localProps.getProperty("flutter.sdk")
        ?: throw GradleException("flutter.sdk non impostato in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false  // versione plugin Firebase
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

include(":app")
