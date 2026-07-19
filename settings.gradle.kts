plugins {
    // Lets Gradle auto-download the Java 25 toolchain the :java module needs,
    // so a plain `./gradlew` build works without a preinstalled JDK 25.
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

rootProject.name = "SwoftLang"
include("java")
