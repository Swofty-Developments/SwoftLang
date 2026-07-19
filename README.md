# SwoftLang

[<img src="https://discordapp.com/assets/e4923594e694a21542a489471ecffa50.svg" alt="Discord" height="55" />](https://discord.swofty.net)

A scripting language for building Minecraft servers on [Minestom](https://minestom.net/). You write commands, events, GUIs, scoreboards, custom items and mobs in a readable, English-flavored syntax. An OCaml compiler checks the whole script before the server boots; a Java runtime executes it.

> **Note**: This is under active development and is not yet production-ready.

```swoftlang
command "heal" {
    arguments {
        target: optional<Player>
    }

    execute {
        set who to args.target otherwise sender
        set who.health to who.max_health
        send "<green>Healed ${who.name}" to who
    }
}
```

Misspell `health`, drop the `otherwise`, or `wait 5 seconds` in a sync handler, and the script fails to compile — with a `file:line:col` caret and a hint, before anyone connects.

## Features

- **Compile-checked** - a real typechecker runs before the server does. Property typos, missing values, and threading mistakes are compile errors, not runtime crashes.
- **No null** - `optional<T>` with `exists` and `otherwise`; the compiler refuses to let a maybe-missing value be used unchecked.
- **Async without callbacks** - `wait`, `spawn`, and virtual threads. The compiler colors sync vs async code so you can't freeze a tick by accident.
- **First-class Minestom** - commands, events, GUIs, scoreboards, tablists, bossbars, custom items, mobs, entities, particles, sounds, worlds, and raw packets.
- **Persistence built in** - `persistent kills for Player`, keyed and saved across restarts, on files, SQLite, MySQL, or MongoDB.
- **Addons are just SwoftLang** - the standard library (holograms, NPCs, music) is written in the language itself. Import one with a single line.

## Documentation

Full documentation is at **[lang.swofty.net](https://lang.swofty.net)** — every snippet on every page is validated against the real compiler.

- [Guide](https://lang.swofty.net/guide/) — a numbered course from setup to shipping a server
- [Reference](https://lang.swofty.net/reference/) — syntax, builtins, and every content system
- [Libraries](https://lang.swofty.net/libraries/) — the stdlib addons, and how to write your own
- [Examples](https://lang.swofty.net/examples/) — real Skript plugins ported whole, side by side

The site source is in [`docs/`](docs/); run it locally with `cd docs && npm install && npm run docs:dev`.

## Quick Start

Download `swoftlang-server.jar` from the [latest release](https://github.com/Swofty-Developments/SwoftLang/releases). It is one self-contained jar — the compiler for your OS is bundled inside, so all you need is a **Java 25 runtime**.

```bash
mkdir my-server && cd my-server
mv ~/Downloads/swoftlang-server.jar .

mkdir scripts
cat > scripts/hello.sw <<'SW'
server {
    auth: offline
    port: 25565
}

event PlayerJoin {
    execute { send "<green>Welcome, ${event.player.name}!" to event.player }
}
SW

java -jar swoftlang-server.jar
```

The server loads every `.sw` file in `scripts/`, compiling each one on startup. Edit a script, restart, done. Set `auth: mojang` for online mode.

## Building from source

You only need this to hack on the language itself. Requirements: **JDK 21** (Gradle runs on it; the `:java` module compiles against a Java 25 toolchain, auto-provisioned) and **OCaml + dune ≥ 3.0** for the compiler.

```bash
cd compiler && dune build && cd ..      # build swoftc
./gradlew :java:jar                      # build the server jar
java -jar java/build/libs/java.jar       # run from the repo root

swoftc check scripts/myscript.sw                                  # compile-check with diagnostics
./gradlew :java:execHarness -PharnessArgs="scripts/showcase.sw"   # run a script headless
cd compiler && dune test                                          # compiler tests
```

During development the runtime finds `swoftc` (at `compiler/_build/default/bin/main.exe`) via the `SWOFTC` env var, `PATH`, or by walking up the tree — so you never need to rebuild the jar to test a compiler change.

## How it works

```
script.sw → swoftc (OCaml) → JSON AST → loader → tree-walking executor (Java/Minestom)
```

The compiler does the hard part — tokenizing, parsing, typechecking, option narrowing, async coloring — and emits a JSON tree. The runtime walks that tree. Both sides share one contract: the JSON schema plus a `property-table.json` fixture that the OCaml tests and the Java harness both verify, so the compiler's idea of `player.health` can't drift from what the runtime resolves.

## Credits

Thanks to the [Minestom](https://minestom.net/) community, and to everyone who has [contributed](https://github.com/Swofty-Developments/SwoftLang/graphs/contributors).

## License

See [LICENSE](LICENSE).
