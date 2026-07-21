---
title: Setup
---

<StepHeader>
a running server that answers <code>/hello</code> — the edit-run loop you'll use for the rest of the course.
</StepHeader>

SwoftLang is a scripting language for Minecraft servers. You write `.sw` files in an
English-flavored syntax; the `swoftc` compiler parses and typechecks them; a
[Minestom](https://minestom.net)-based runtime executes them on a live server. The
compiler is the point: missing-value bugs, property typos, and threading mistakes are
**compile errors before the server boots** — this guide shows you real ones at every step.

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">The course</h2><span class="sw-hub-sec-note">16 steps · one concept each · ending runnable</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/guide/"><span class="sw-hub-num">01</span><span class="sw-hub-body"><span class="sw-hub-title">Setup</span><span class="sw-hub-desc">Install Java, download the server, run your first script. You're here.</span></span></a>
<a class="sw-hub-card" href="/guide/commands"><span class="sw-hub-num">02</span><span class="sw-hub-body"><span class="sw-hub-title">Your First Command</span><span class="sw-hub-desc">Command blocks, arguments, and the sender.</span></span></a>
<a class="sw-hub-card" href="/guide/events"><span class="sw-hub-num">03</span><span class="sw-hub-body"><span class="sw-hub-title">Events</span><span class="sw-hub-desc">Handle server events with typed receiver blocks.</span></span></a>
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

## Install Java 25

The server runs on **Java 25** — Minestom tracks the latest Minecraft, which is Java-25
bytecode. Grab a JDK 25 build from [Adoptium](https://adoptium.net/temurin/releases/?version=25)
(or your package manager) and confirm:

```bash
$ java -version
openjdk version "25" ...
```

That's the *only* thing you install. The `swoftc` compiler is baked into the server jar and
extracted automatically at boot — there's no toolchain to set up and nothing to build from
source.

## Download the server

Grab the latest **`swoftlang-server.jar`** from the
[Releases page](https://github.com/Swofty-Developments/SwoftLang/releases/latest) and drop it
in a fresh folder. Everything lives next to the jar:

```
my-server/
├── swoftlang-server.jar
└── scripts/
    └── hello.sw
```

## Write your first script

The server loads **every `.sw` file in the `scripts/` folder beside the jar**. Create
`scripts/hello.sw`:

```swoftlang
command "hello" {
    description: "Sends a friendly greeting"

    execute {
        send "<lime>Hello from SwoftLang!" to sender
    }
}
```

## Run the server

```bash
java -jar swoftlang-server.jar
```

On boot the server compiles every script in `scripts/` — any mistake surfaces as
`file:line:col: error: message` with a caret pointing at your code, *before* the world loads —
then starts a Minestom server on `0.0.0.0:25565` (offline mode by default; you'll configure
auth, MOTD, and the rest in [Step 16](/1.2.0/guide/ship-it)) and registers what it found. Join with a
current Minecraft client and type `/hello`:

> **Hello from SwoftLang!** — in lime green.

That's the whole loop: edit a `.sw` file, restart the server. Prefer save-and-see? Run with
`--debug`:

```bash
java -jar swoftlang-server.jar --debug          # tracer + hot reload on ws port 25580
java -jar swoftlang-server.jar --debug 9000     # pick the port
```

`--debug` turns on two dev-workflow features:

- **Hot reload on save.** The server watches `scripts/` and, the moment you save a `.sw`,
  recompiles just that file with `swoftc`. On a clean compile it applies a **tick-safe
  reload**: every declaration is re-registered from scratch — commands, event handlers,
  scoreboards, tablists, bossbars, GUIs, mobs, items, holograms, NPCs, block handlers —
  while running schedules are cancelled and script-spawned entities are torn down so
  nothing leaks across the swap. No JVM restart, no reconnect. If the recompile **fails**,
  the old handlers keep running and the `swoftc` error is streamed to the tracer instead —
  a broken save never takes the server down. Persistent variables and their storage
  backend survive a reload untouched.
- **Live execution tracer.** A small WebSocket server (default port `25580`) streams
  handler enter/exit and per-statement execution events. It is best-effort and lossy under
  load — the tick thread never blocks on it — and costs a normal (non-`--debug`) server
  nothing. This is what the VS Code extension connects to.

::: tip Editor support
Install the **SwoftLang** VS Code extension for syntax highlighting, inline type errors as you
type, and — with `--debug` — a live tracer that highlights each line as it runs.
:::

::: warning Reload is not a live migration
A reload re-runs registration, not your handlers' past effects. State held only in local
variables or entity tags is rebuilt from whatever the new script does on the next event —
put anything that must outlive an edit in a [`persistent`](/1.2.0/guide/persistence) variable.
:::

Next: that `command` block, taken seriously.
