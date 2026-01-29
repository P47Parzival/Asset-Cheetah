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

// Evaluate :app first for dependency resolution
project(":app").evaluationDependsOn(":app")

// Workaround for Isar & AGP 8+ namespace issue - applied after all projects are evaluated
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
        if (android.namespace == null) {
            android.namespace = project.group.toString()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
