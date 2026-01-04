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
        applicationId = "com.sage.books"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- SIGNING CONFIGURATION ---
    signingConfigs {
        create("release") {
            val keystoreFile = file("upload-keystore.jks")
            
            // 🛑 SAFETY CHECK: Only try to load the key if the Workflow created it.
            // This prevents "File Not Found" crashes.
            if (keystoreFile.exists()) {
                keyAlias = "upload"
                keyPassword = "sage123"
                storeFile = keystoreFile
                storePassword = "sage123"
            } else {
                // Fallback: If no key found, print a warning but don't crash.
                // This lets the build continue using the default Android debug key.
                println("⚠️ Keystore not found. Using default debug keystore.")
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            }
        }
    }

    // --- BUILD TYPES ---
    buildTypes {
        getByName("release") {
            // Use the configuration we defined above
            signingConfig = signingConfigs.getByName("release")
            // Disable code shrinking to prevent Firebase from breaking
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // MAGIC TRICK: Try to use the Release key for Debug too!
            // This ensures SHA-1 is ALWAYS the same, fixing Google Sign-In issues.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
