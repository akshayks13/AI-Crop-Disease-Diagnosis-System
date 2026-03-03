allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val proj = this
    if (proj.hasProperty("android")) {
        proj.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            if (namespace == null) {
                namespace = "com.cropdiagnosis.${proj.name.replace("-", "_")}"
            }
        }
    } else {
        proj.afterEvaluate {
            if (hasProperty("android")) {
                extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                    if (namespace == null) {
                        namespace = "com.cropdiagnosis.${proj.name.replace("-", "_")}"
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
