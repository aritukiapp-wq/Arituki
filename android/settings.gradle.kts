pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        // Asegúrate de que local.properties existe y flutter.sdk está definido correctamente.
        // Ejemplo de local.properties en Windows: flutter.sdk=C:\\flutter
        // Ejemplo de local.properties en macOS/Linux: flutter.sdk=/Users/username/flutter
        file("local.properties").inputStream().use { properties.load(it) }
        val sdkPath = properties.getProperty("flutter.sdk")
        require(sdkPath != null) { "flutter.sdk not set in local.properties. Make sure you have a " +
                "local.properties file in the C:/zgzapp/android/ directory with the " +
                "flutter.sdk property set to the path of your Flutter SDK." }
        sdkPath
    }

    // Usar File para construir el path es más robusto
    includeBuild(java.io.File(flutterSdkPath, "packages/flutter_tools/gradle").path)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal() // Necesario para que Gradle encuentre el plugin foojay-resolver-convention
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.2" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.1" apply false
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false // ACTUALIZADO a Kotlin 2.1.0
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0" 
}

// Activa la gestión de toolchains.
// El plugin "org.gradle.toolchains.foojay-resolver-convention" aplicado arriba
// debería configurar automáticamente Foojay como un proveedor de toolchains.
toolchainManagement {
    jvm {
        // Al aplicar el plugin "org.gradle.toolchains.foojay-resolver-convention",
        // Foojay se registra automáticamente como un repositorio de toolchains.
        // Si necesitaras especificar una versión de Java particular, lo harías aquí, por ejemplo:
        // javaLanguageVersion.set(JavaLanguageVersion.of(17))
    }
}

include(":app")
