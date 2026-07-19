---
title: Setup
---

<StepHeader>
a working toolchain and a server that answers <code>/hello</code> — the edit-check-run loop you'll use for the rest of the course.
</StepHeader>

SwoftLang is a scripting language for Minecraft servers. You write `.sw` files in an
English-flavored syntax; the `swoftc` compiler parses and typechecks them; a
[Minestom](https://minestom.net)-based runtime executes them on a live server. The
compiler is the point: missing-value bugs, property typos, and threading mistakes are
**compile errors before the server boots** — this guide shows you real ones at every step.

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">The course</h2><span class="sw-hub-sec-note">16 steps · one concept each · ending runnable</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/guide/"><span class="sw-hub-num">01</span><span class="sw-hub-body"><span class="sw-hub-title">Setup</span><span class="sw-hub-desc">The toolchain and the edit-check-run loop. You're here.</span></span></a>
<a class="sw-hub-card" href="/guide/commands"><span class="sw-hub-num">02</span><span class="sw-hub-body"><span class="sw-hub-title">Your First Command</span><span class="sw-hub-desc">Command blocks, arguments, and the sender.</span></span></a>
<a class="sw-hub-card" href="/guide/events"><span class="sw-hub-num">03</span><span class="sw-hub-body"><span class="sw-hub-title">Events</span><span class="sw-hub-desc">Handle Minestom events by name, typed.</span></span></a>
<a class="sw-hub-card" href="/guide/variables-and-types"><span class="sw-hub-num">04</span><span class="sw-hub-body"><span class="sw-hub-title">Variables &amp; Types</span><span class="sw-hub-desc"><code>set … to</code>, inferred locals, and the core type set.</span></span></a>
<a class="sw-hub-card" href="/guide/control-flow"><span class="sw-hub-num">05</span><span class="sw-hub-body"><span class="sw-hub-title">Control Flow</span><span class="sw-hub-desc">Conditions, loops, brace-free single statements.</span></span></a>
<a class="sw-hub-card" href="/guide/functions"><span class="sw-hub-num">06</span><span class="sw-hub-body"><span class="sw-hub-title">Functions &amp; Lambdas</span><span class="sw-hub-desc">Declarations, returns, first-class functions.</span></span></a>
<a class="sw-hub-card" href="/guide/options"><span class="sw-hub-num">07</span><span class="sw-hub-body"><span class="sw-hub-title">Options — No More Null</span><span class="sw-hub-desc"><code>optional&lt;T&gt;</code>, <code>exists</code>, and <code>otherwise</code>.</span></span></a>
<a class="sw-hub-card" href="/guide/properties"><span class="sw-hub-num">08</span><span class="sw-hub-body"><span class="sw-hub-title">Player &amp; World Properties</span><span class="sw-hub-desc">The checked property table, reads and writes.</span></span></a>
<a class="sw-hub-card" href="/guide/async"><span class="sw-hub-num">09</span><span class="sw-hub-body"><span class="sw-hub-title">Async</span><span class="sw-hub-desc"><code>wait</code>, <code>spawn</code>, virtual threads, and coloring.</span></span></a>
<a class="sw-hub-card" href="/guide/persistence"><span class="sw-hub-num">10</span><span class="sw-hub-body"><span class="sw-hub-title">Persistence</span><span class="sw-hub-desc">Persistent state keyed by player, saved across restarts.</span></span></a>
<a class="sw-hub-card" href="/guide/guis"><span class="sw-hub-num">11</span><span class="sw-hub-body"><span class="sw-hub-title">GUIs</span><span class="sw-hub-desc">Declarative inventories and click handlers.</span></span></a>
<a class="sw-hub-card" href="/guide/items-and-mobs"><span class="sw-hub-num">12</span><span class="sw-hub-body"><span class="sw-hub-title">Items &amp; Mobs</span><span class="sw-hub-desc">Declare custom items and mobs and place them.</span></span></a>
<a class="sw-hub-card" href="/guide/modules"><span class="sw-hub-num">13</span><span class="sw-hub-body"><span class="sw-hub-title">Modules &amp; Addons</span><span class="sw-hub-desc"><code>import</code>, <code>export</code>, and shared module state.</span></span></a>
<a class="sw-hub-card" href="/guide/rpg-items"><span class="sw-hub-num">14</span><span class="sw-hub-body"><span class="sw-hub-title">Build an RPG Item System</span><span class="sw-hub-desc">A capstone tying items, events, and state together.</span></span></a>
<a class="sw-hub-card" href="/guide/offline-players"><span class="sw-hub-num">15</span><span class="sw-hub-body"><span class="sw-hub-title">Offline Players</span><span class="sw-hub-desc">The <code>OfflinePlayer</code> type and the seen-store.</span></span></a>
<a class="sw-hub-card" href="/guide/ship-it"><span class="sw-hub-num">16</span><span class="sw-hub-body"><span class="sw-hub-title">Ship It</span><span class="sw-hub-desc">Auth, MOTD, config — take the server live.</span></span></a>
</div>
</div>

## Install the toolchain

Two things:

- **JDK 21** — the runtime uses virtual threads, so 21 is a hard floor.
- **OCaml + dune** — to build `swoftc`. The only library dependency is `yojson`.

::: code-group

```bash [nix-shell]
nix-shell -p ocaml dune_3 ocamlPackages.yojson
```

```bash [opam]
opam install dune yojson
```

:::

## Build the compiler

```bash
cd compiler
dune build
```

The binary lands at `compiler/_build/default/bin/main.exe`. Check it works:

```bash
$ ./compiler/_build/default/bin/main.exe --version
swoftc 2.0.0
```

Put it on your `PATH` as `swoftc` (or export `SWOFTC=/path/to/main.exe` — the server
runtime honors the same variable when it compiles your scripts at boot).

## Write your first script

The engine loads every `.sw` file it finds in the `scripts/` directory next to the server.
Create `scripts/hello.sw`:

```swoftlang
command "hello" {
    description: "Sends a friendly greeting"

    execute {
        send "<lime>Hello from SwoftLang!" to sender
    }
}
```

## Check it

```bash
$ swoftc check scripts/hello.sw
$ echo $?
0
```

Silence means it's good. When something is wrong, errors come out as
`file:line:col: error: message` with a caret pointing at your code — you'll meet plenty
of real ones through this course, on purpose.

## Run the server

```bash
./gradlew :java:run
```

This boots a Minestom server on `0.0.0.0:25565` (offline mode by default — you'll
configure auth, MOTD, and the rest in [Step 16](/guide/ship-it)), compiles every script
in `scripts/`, and registers what it finds. Join with a 1.21.4 client and type `/hello`:

> **Hello from SwoftLang!** — in lime green.

That's the whole loop: edit a `.sw` file, `swoftc check` it, restart the server. The
repository's `scripts/` directory ships a set of real examples that double as the
compiler's acceptance suite — worth skimming as you go.

Next: that `command` block, taken seriously.
