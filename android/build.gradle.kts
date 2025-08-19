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

// Dynamically set namespace for library subprojects that are missing it.
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                if (namespace == null) {
                    // Specifically fix isar_flutter_libs
                    if (project.name == "isar_flutter_libs") {
                        namespace = "dev.isar.isar_flutter_libs"
                    } else {
                        // Generic fallback for other potential libraries
                        namespace = "com.example.${project.name.replace("[^a-zA-Z0-9_]".toRegex(), "_")}"
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
