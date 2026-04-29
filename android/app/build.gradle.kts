import java.net.URLDecoder

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.alfahmi.absensi.sma"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // FIX 1: Use isCoreLibraryDesugaringEnabled and the = sign
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // FIX 2: Modern way to set jvmTarget to avoid the deprecation warning
//    kotlinOptions {
//        jvmTarget = "17"
//    }
    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.alfahmi.absensi.sma"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Ambil APP_NAME dari --dart-define
        val dartDefinesString = project.properties["dart-defines"] as String?
        var appName = "SMA IT AL FAHMI PALU"
        if (dartDefinesString != null) {
            val defines = dartDefinesString.split(",")
            for (define in defines) {
                val pair = define.split("=")
                if (pair.size == 2 && pair[0] == "APP_NAME") {
                    appName = URLDecoder.decode(pair[1], "UTF-8")
                }
            }
        }
        manifestPlaceholders += mapOf("appName" to appName)

        // FIX 3: Use the = sign for multiDexEnabled
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    androidResources {
        noCompress.add("tflite")
    }
}
flutter {
    source = "../.."
}

// ========================================================
// PERBAIKAN 2: Gunakan tanda kurung () dan kutip ganda ""
// ========================================================
dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.17.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.5.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}