allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Sonar text:S8569: bloquea las versiones de dependencias resueltas para
    // que el build sea reproducible. Esto activa el mecanismo de Gradle;
    // el archivo gradle.lockfile de cada módulo debe generarse localmente
    // ejecutando, con el SDK de Android instalado:
    //   ./gradlew :app:dependencies --write-locks
    // (no se puede generar desde este entorno: no tiene Android SDK ni
    // acceso a los repositorios de Google/Maven Central).
    dependencyLocking {
        lockAllConfigurations()
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

tasks.register<Delete>("clean") {
    group = "build"
    description = "Deletes the root build directory."
    delete(rootProject.layout.buildDirectory)
}
