allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = File(rootProject.projectDir, "../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val projectPath = project.projectDir.absolutePath
    if (projectPath.length >= 2 && newBuildDir.absolutePath.length >= 2 &&
        !projectPath.substring(0, 1).equals(newBuildDir.absolutePath.substring(0, 1), ignoreCase = true)
    ) {
        // Project and build directory are on different drives. 
        // Use a temporary directory on the same drive as the project to avoid "different roots" exception.
        val projectName = rootProject.projectDir.parentFile.name
        val cacheBuildDir = File(System.getProperty("java.io.tmpdir"), "flutter_builds/${projectName}/${project.name}")
        project.layout.buildDirectory.set(cacheBuildDir)
    } else {
        val newSubprojectBuildDir = File(newBuildDir, project.name)
        project.layout.buildDirectory.set(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
