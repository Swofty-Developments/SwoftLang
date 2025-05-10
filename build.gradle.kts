// Configure all projects (including subprojects)
allprojects {
    repositories {
        mavenCentral()
        // Minestom snapshots live on JitPack:
        maven("https://jitpack.io")
    }
}

// Configure native build task
tasks.register<Exec>("buildNative") {
    workingDir = file("native")
    commandLine = listOf("cmake", ".", "-B", "build")
    doLast {
        exec {
            workingDir = file("native")
            commandLine = listOf("cmake", "--build", "build")
        }
    }
}