// File: android/build.gradle.kts

apply(plugin = "com.google.gms.google-services")



buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services plugin for Firebase
        classpath("com.google.gms:google-services:4.3.15")

        // Android Gradle Plugin (update version if needed)
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: custom build directory structure
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
