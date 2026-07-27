# Libraries

<p class="sw-lead">The standard library ships written <strong>in SwoftLang</strong>. An addon is a
<code>.sw</code> file that <code>export</code>s functions; importing one is one line.</p>

```swoftlang
import "music"

command "anthem" {
    execute {
        play_song_for_all("anthem.nbs")
    }
}
```

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Shipped addons</h2><span class="sw-hub-sec-note">each ends with how it's built</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/1.5.0/libraries/music"><span class="sw-hub-body"><span class="sw-hub-title">Music</span><span class="sw-hub-desc"><code>import "music"</code> — radius and broadcast song helpers over NBS playback.</span></span></a>
<a class="sw-hub-card" href="/1.5.0/libraries/abilities"><span class="sw-hub-body"><span class="sw-hub-title">Abilities</span><span class="sw-hub-desc"><code>import "abilities"</code> — named item abilities on per-player cooldowns.</span></span></a>
</div>
</div>

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Authoring</h2><span class="sw-hub-sec-note">build your own</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/1.5.0/libraries/writing-an-addon"><span class="sw-hub-body"><span class="sw-hub-title">Writing an Addon</span><span class="sw-hub-desc">Build a <code>titles.sw</code> addon from an empty file to first-class-function tricks, every step compiled.</span></span></a>
</div>
</div>

The addons double as the reference implementations for
[writing your own](./writing-an-addon). The rest of this page is the import system
itself — resolution, exports, and module state.

## The import system {#the-import-system}

`import "<spec>"` at the top level, where the spec is either a **module name** or a
**relative path**:

| Form | Resolves to |
|---|---|
| `import "music"` | `music.sw` in the importing script's directory, else in the addon path |
| `import "./lib/util.sw"` | exactly that file, relative to the importing script |

The addon path defaults to an `addons/` directory next to your scripts and is
overridable with [`swoftc --addon-path <dir>`](/1.5.0/reference/cli). A failed resolution
tells you everywhere it looked:

```
e_impbad.sw:1:1: error: cannot resolve import "warp_utils" (looked for warp_utils.sw and addons/warp_utils.sw)
```

Imports are resolved **at compile time**: the entry script and every transitively
imported module compile as one unit, typechecked together — types, optionals, and
async coloring all flow across module boundaries. The output is a single
[bundle JSON](/1.5.0/reference/json-ast#bundles). Import graphs must be acyclic:

```
b.sw:1:1: error: import cycle: a -> b -> a
```

Importing the same module twice (directly or through two paths) is a no-op — one
copy compiles, one copy loads, one copy of its state exists.

## Exports {#exports}

Symbols are private by default. `export` in front of a declaration makes it visible
to importers:

```swoftlang
export function greet(target: Player) {
    send "<green>hello from a library" to target
}

export async function delayed_greet(target: Player) {
    wait 1 seconds
    greet(target)
}

function internal_detail() return 42     // invisible to importers
```

`export` works on `function` (sync or async), `item`, `mob`, `gui`, `scoreboard`,
`tablist`, and `bossbar` declarations. Lambdas are values, so first-class functions
cross module boundaries through exported functions — the
[abilities addon](./abilities)'s `on_item_use` / `with_cooldown` handler API is exactly
that.

Calling a private function from outside is a compile error that names the module:

```
e_private.sw:5:9: error: function 'ability_put' is private to module 'abilities' (addons/abilities.sw); add 'export' to its declaration to call it from here
```

**Commands and events are effects, not symbols.** A `command`, receiver block, `api`
route, `every` scheduler, or `Packet` listener declared in a module registers
the moment the module is imported — that's how the abilities addon installs its
item-use listener. `export` on them is rejected:

```
e_expcmd.sw:1:8: error: commands and events always register when their module is imported (they are effects, not symbols); remove 'export'
```

Two modules exporting the same symbol name is a load error naming both modules —
there is no shadowing and no aliasing (v1).

## Module-level variables {#module-vars}

`var name = expr` at the top level declares module state: private to the file,
initialized at load, alive for the server session, **not** persistent (use
[`persistent`](/1.5.0/guide/persistence) for data that must survive restarts).

```swoftlang
var opens = 0

export function count_open() {
    set opens to opens + 1
    return opens
}
```

Module-level `var`s are shared, live state: every call into the module — from any
command, event, api handler, or schedule — reads and writes the same variable.
Reads and writes are individually safe across concurrent async tasks, but a
compound update such as `set opens to opens + 1` is a read-then-write and is
**not atomic**: two async tasks updating the same module variable at the same time
can lose one of the updates. If a counter must be exact under concurrency, funnel
the updates through a single [schedule](/1.5.0/reference/schedulers) or a persistent
variable instead of racing async tasks over one module var.

## Checking scripts that import

`swoftc check` follows imports, so CI stays one line — point `--addon-path` at your
addons directory:

```sh
swoftc check scripts/lobby.sw --addon-path addons
```

Ready to write one? The [tutorial](./writing-an-addon) builds a `titles.sw` addon
from an empty file to first-class-function tricks, every step compiled.
