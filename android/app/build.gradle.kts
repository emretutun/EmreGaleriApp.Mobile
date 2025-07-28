plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin, Android ve Kotlin pluginlerinden sonra uygulanmalı
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.emregalerimobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // NDK sürümü burada sabit belirtildi

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"  // String olarak verilmeli, toString() yerine direkt "11"
    }

    defaultConfig {
        applicationId = "com.example.emregalerimobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
