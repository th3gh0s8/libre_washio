plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.powersoft.washio"
    compileSdk = 34
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "com.powersoft.washio"
        minSdk = 21
        targetSdk = 34
        // Correctly handle potentially missing properties with defaults
        versionCode = (project.findProperty("flutterVersionCode") as String?)?.toInt() ?: 1
        versionName = project.findProperty("flutterVersionName") as String? ?: "1.0"

        resValue("string", "app_name", "Washio")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
