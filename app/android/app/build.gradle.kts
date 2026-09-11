import java.io.FileInputStream
import java.util.Properties

// Signing material for a release build (§7.2). Absent on a clone and in CI for
// a pull request — it only exists where a release is actually being produced,
// which is the release workflow after it has written it from the repository
// secrets.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.nohzoh.fieldtally"
    // Forcé à 37 : une dépendance du §5.1 l'exige (flutter.compileSdkVersion vaut 36).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requis par flutter_local_notifications (§3.7) pour que java.time soit
        // disponible sur les Android antérieurs à l'API 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.nohzoh.fieldtally"
        // Android 8.0 — valeur par défaut proposée en §14 de la spec.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key when there is no keystore, so
            // `flutter build apk --release` still works on a fresh clone. The
            // release workflow refuses to publish anything in that state — an
            // APK signed with the debug key would be one no future update
            // could ever replace.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
