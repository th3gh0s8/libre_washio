plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.powersoft.washio"
    // Updated to 35 as required by dependencies
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // Added to align Kotlin JVM target with Java's, resolving the build error.
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.powersoft.washio"
        minSdk = 21
        // Updated to match compileSdk
        targetSdk = 35
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
