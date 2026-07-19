#!/usr/bin/env bash
# SwoftLang live demo launcher.
#
# Boots the SwoftLang server in the FOREGROUND on 0.0.0.0:25565 in ONLINE
# (Mojang auth) mode, loading only demo/scripts/demo.sw. Connect a real
# Minecraft client to localhost:25565.
#
# Rebuild the jar first (from the repo root) if you changed java/:
#   nix-shell -p jdk21 --run './gradlew :java:jar'
set -euo pipefail

# --- locate things (script is demo/run.sh; repo root is its parent) ---
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DEMO_DIR/.." && pwd)"
JAR="$REPO_DIR/java/build/libs/java.jar"
SWOFTC_BIN="$REPO_DIR/compiler/_build/default/bin/main.exe"

# --- JDK 25 (resolved from nix; override by exporting JAVA_HOME) ---
# net.minestom:minestom:2026.07.12-26.2 is Java-25 bytecode, so the runtime
# must be JDK 25 (a JDK 21 launcher throws UnsupportedClassVersionError).
if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME:-}/bin/java" ]]; then
    JAVA_HOME="$(nix-shell -p jdk25 --run 'printf %s "$JAVA_HOME"')"
fi
export JAVA_HOME
JAVA="$JAVA_HOME/bin/java"

# --- put swoftc on PATH / SWOFTC so the engine can (re)compile scripts;
#     the checked-in demo.sw.json sidecar is used as a fallback anyway ---
if [[ -x "$SWOFTC_BIN" ]]; then
    export SWOFTC="$SWOFTC_BIN"
    export PATH="$(dirname "$SWOFTC_BIN"):$PATH"
fi

if [[ ! -f "$JAR" ]]; then
    echo "error: $JAR not found - build it first from $REPO_DIR:" >&2
    echo "  nix-shell -p jdk21 --run './gradlew :java:jar'" >&2
    exit 1
fi

# The engine reads ./scripts/*.sw relative to the working directory, so run
# from demo/ to load ONLY demo/scripts/demo.sw.
cd "$DEMO_DIR"
echo "Starting SwoftLang demo on 0.0.0.0:25565 (online mode) - Ctrl-C to stop"
exec "$JAVA" -jar "$JAR"
