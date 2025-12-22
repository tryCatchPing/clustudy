import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Ensure legacy isar_flutter_libs plugin is compatible with AGP 8 requirements.
subprojects {
    if (name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }

        afterEvaluate {
            (extensions.findByName("android") as? LibraryExtension)?.apply {
                // Use compileSdk 35 for 16KB page size support (Android 15 requirement)
                compileSdk = 35
                // Ensure 16KB page size support for native libraries
                packaging {
                    jniLibs {
                        useLegacyPackaging = false
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
