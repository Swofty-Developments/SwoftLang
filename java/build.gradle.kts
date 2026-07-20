// java/build.gradle.kts
plugins {
    java
    application          // gives :run for quick tests
}

java {
    toolchain {
        // net.minestom:minestom:2026.07.12-26.2 ships Java 25 bytecode and its
        // Gradle module metadata declares org.gradle.jvm.version=25, so the
        // consumer toolchain must be 25 for variant selection to succeed. The
        // Gradle launcher still runs on JDK21; JDK25 is used only as the compile
        // toolchain (its install path is registered in the root gradle.properties).
        languageVersion.set(JavaLanguageVersion.of(25))
    }
}

repositories {
    mavenCentral()
    maven("https://jitpack.io")  // Make sure this is here for Minestom
}

dependencies {
    implementation("net.minestom:minestom:2026.07.12-26.2")
    // Polar world format (phase-6 worlds), matched to the current Minestom.
    implementation("dev.hollowcube:polar:1.16.0")
    // Polar's PolarLoader has @NotNull-annotated fastutil (Short2ObjectMap)
    // parameters; minestom pulls fastutil only at runtime, so javac needs it on
    // the compile classpath to read Polar's annotated bytecode. Match minestom's
    // forced 8.5.18.
    implementation("it.unimi.dsi:fastutil:8.5.18")
    // Adventure 5.2.0 to match the version net.minestom:minestom:2026.07.12-26.2
    // forces transitively (adventure-api 5.2.0). 4.18.0 is binary-incompatible
    // with a mixed 5.x classpath.
    implementation("net.kyori:adventure-text-minimessage:5.2.0")
    implementation("net.kyori:adventure-text-serializer-legacy:5.2.0")
    implementation("com.google.code.gson:gson:2.14.0")

    // Persistence backends (net.swofty.persist)
    implementation("org.xerial:sqlite-jdbc:3.47.1.0")
    implementation("com.mysql:mysql-connector-j:9.1.0")
    implementation("org.mongodb:mongodb-driver-sync:5.2.1")
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

// Phase-7 event catalog: ship compiler/data/events.json inside the jar as
// /events.json so EventCatalog's classpath fallback works in a deployed
// server (outside the repo root there is no compiler/data on disk).
tasks.processResources {
    from(rootProject.file("compiler/data/events.json"))
}

tasks.register("showDependencies") {
    doLast {
        configurations.compileClasspath.get().forEach {
            println(it)
        }
    }
}

tasks.register<JavaExec>("execHarness") {
    mainClass.set("net.swofty.harness.ExecHarness")
    classpath = sourceSets.main.get().runtimeClasspath
    workingDir = rootDir
    // The :java module compiles to Java-25 bytecode, so the harness must run on
    // the JDK-25 toolchain even though the Gradle launcher itself is JDK 21.
    javaLauncher.set(javaToolchains.launcherFor {
        languageVersion.set(JavaLanguageVersion.of(25))
    })
    if (project.hasProperty("harnessArgs")) {
        args((project.property("harnessArgs") as String).split(" "))
    }
}

tasks.register<JavaExec>("debugSmoke") {
    mainClass.set("net.swofty.harness.DebugSmoke")
    classpath = sourceSets.main.get().runtimeClasspath
    workingDir = rootDir
    javaLauncher.set(javaToolchains.launcherFor {
        languageVersion.set(JavaLanguageVersion.of(25))
    })
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
