// java/build.gradle.kts
plugins {
    java
    application          // gives :run for quick tests
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

repositories {
    mavenCentral()
    maven("https://jitpack.io")  // Make sure this is here for Minestom
}

dependencies {
    implementation("net.minestom:minestom-snapshots:ebaa2bbf64")
}

application {
    mainClass.set("net.swofty.Bootstrap")
}

sourceSets {
    main {
        java {
            srcDir("src/main/java")
        }
        resources {
            srcDir("src/main/resources")
        }
    }
    test {
        java {
            srcDir("src/test/java")
        }
        resources {
            srcDir("src/test/resources")
        }
    }
}

tasks.processResources {
    // Keep the first copy we hit; silently drop the duplicate
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from("$rootDir/native/build/Debug") {          // after `build-native`
        include("SwoftLang.dll")
        into("Debug")                              // matches resourcePath
    }
}

/* ─────────────────────────────────────────────────────────────── */
/*  Generate JNI headers into native/include before native build   */
/* ─────────────────────────────────────────────────────────────── */
tasks.register<JavaCompile>("genJniHeaders") {
    val headersDir = file("${rootProject.projectDir}/native/include")
    
    // Only include classes in the 'net/swofty/native' package
    source = fileTree("src/main/java") {
        include("net/swofty/nativebridge/**/*.java")
    }
    
    // Required classpath
    classpath = sourceSets.main.get().compileClasspath
    
    // Configure javac
    options.compilerArgs = listOf(
        "-h", headersDir.absolutePath
    )
    
    // The output directory for class files (not headers)
    destinationDirectory.set(layout.buildDirectory.dir("tmp/jni-header-stubs"))
    
      // Clean existing headers and ensure directory exists
    doFirst { 
        // Delete all .h files in the include directory
        if (headersDir.exists()) {
            headersDir.listFiles()?.forEach { file ->
                if (file.name.endsWith(".h")) {
                    file.delete()
                    println("Deleted existing header: ${file.name}")
                }
            }
        } else {
            headersDir.mkdirs()
            println("Created include directory: ${headersDir.absolutePath}")
        }
        
        println("Generating JNI headers in: ${headersDir.absolutePath}")
        println("Source files: ${source.files}")
    }
    
    // Report what was generated
    doLast {
        println("Generated headers:")
        headersDir.listFiles()?.forEach { file ->
            if (file.name.endsWith(".h")) {
                println(" - ${file.name}")
            }
        }
    }
}

/* Make Java compilation depend on the header generation */
tasks.named("compileJava") { dependsOn("genJniHeaders") }
tasks.named("run") { dependsOn(":buildNative") }

tasks.register("showDependencies") {
    doLast {
        configurations.compileClasspath.get().forEach {
            println(it)
        }
    }
}

tasks.withType<Jar> {
    // Include everything in the final JAR
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) })
    
    // Avoid duplicate META-INF files
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    
    // Add manifest with main class
    manifest {
        attributes["Main-Class"] = "net.swofty.Bootstrap"
    }
}
