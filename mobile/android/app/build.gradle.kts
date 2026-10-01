import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release (07.1 COM-03).
//
// `key.properties` y el `.jks` no se versionan (ver .gitignore). Se generan
// una sola vez con `keytool` y se copian fuera del repositorio. Si el archivo
// no está, el release cae a la firma de debug para que `flutter run --release`
// siga funcionando en local: sirve para probar, no para publicar.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hayFirmaRelease = keystorePropertiesFile.exists()
if (hayFirmaRelease) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.quickbite.quickbite_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.quickbite.quickbite_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirmaRelease) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hayFirmaRelease) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "QuickBite: falta android/key.properties; el release se firma con la " +
                        "llave de debug y NO se puede subir a Play. Ver mobile/docs/08 o " +
                        "COM-03 en 07.1.",
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
