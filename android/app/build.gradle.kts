plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sage.books"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sage.books"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

  // THIS SIGNING BLOCK
    signingConfigs {
        create("release") {
            // We hardcoded these in the workflow, so we hardcode them here
            keyAlias = "upload"
            keyPassword = "sage123"
            storeFile = file("upload-keystore.jks")
            storePassword = "sage123"
        }
    }

    // BUILD TYPES TO USE THE KEY
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // MAGIC TRICK: Use the Release key for Debug too!
            // This ensures SHA-1 is ALWAYS the same.
            signingConfig = signingConfigs.getByName("release")
        }
    }


flutter {
    source = "../.."
}
