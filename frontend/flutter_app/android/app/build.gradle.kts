plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cropdiagnosis.flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Removed the old kotlinOptions { jvmTarget = "17" } block from here

    defaultConfig {
        applicationId = "com.cropdiagnosis.flutter_app"
        minSdk = flutter.minSdkVersion // TFLite Flex ops usually require 21+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

dependencies {
    // FIXED: Added parentheses and double quotes for Kotlin DSL
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.12.0")
}

flutter {
    source = "../.."
}
