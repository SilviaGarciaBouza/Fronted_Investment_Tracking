pluginManagement {
   /* val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }*/ 
        val flutterSdkPath = runCatching {
        val properties = java.util.Properties()
        properties.load(java.io.FileInputStream(java.io.File("local.properties")))
        properties.getProperty("flutter.sdk")
    }.getOrNull()
    val flutterSdk = flutterSdkPath ?: System.getenv("FLUTTER_ROOT")
    check(flutterSdk != null) { "Flutter SDK not found in local.properties or FLUTTER_ROOT env variable." }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
