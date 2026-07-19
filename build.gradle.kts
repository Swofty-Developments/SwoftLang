// Configure all projects (including subprojects)
allprojects {
    repositories {
        mavenCentral()
        // Minestom snapshots live on JitPack:
        maven("https://jitpack.io")
    }
}

// Build the OCaml compiler (swoftc). NixOS users: wrap the build with
// `nix-shell -p ocaml dune_3 --run './gradlew buildCompiler'` so dune is on PATH.
// Skipped when dune is unavailable — SwoftcCompiler falls back to the SWOFTC env
// var, `swoftc` on PATH, or a `.sw.json` sidecar next to each script.
tasks.register<Exec>("buildCompiler") {
    workingDir = rootDir
    commandLine = listOf("sh", "-c", "cd compiler && dune build")
    onlyIf {
        val hasDune = try {
            ProcessBuilder("sh", "-c", "which dune").start().waitFor() == 0
        } catch (e: Exception) {
            false
        }
        if (!hasDune) {
            logger.lifecycle("dune not found on PATH; skipping buildCompiler (SwoftcCompiler will use PATH/sidecar fallback)")
        }
        hasDune && file("compiler").isDirectory
    }
}
