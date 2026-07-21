# Worlds

Create, load, clone, and delete whole worlds from scripts — backed by vanilla Anvil
directories, compact Polar files, or Polar blobs inside your existing
[storage backend](./server-config#storage-phase-3).

```swoftlang
command "arena" {
    execute {
        create world "arena" with polar_loader("worlds")
        load world "arena" with polar_loader("worlds")
        set hub to world("arena")
        if hub exists {
            set sender.world to hub
        }
    }
}
```

## Loaders

A **loader** is a value describing where world bytes live. Every world statement takes
one, so the same script can juggle formats:

| Expression | Type | Storage |
|---|---|---|
| `anvil_loader("worlds/")` | `WorldLoader` | vanilla region directories — one folder per world |
| `polar_loader("worlds/")` | `WorldLoader` | Polar files — one compact `.polar` file per world |
| `polar_storage_loader(<backend>)` | `WorldLoader` | Polar bytes as blobs in a storage backend, keyed by world name |

`polar_storage_loader` takes the same backend syntax as the
[`storage { }` block](./server-config#storage-phase-3) — files, sqlite, mysql, or
mongodb — so worlds can live next to your persistent variables:

```swoftlang
command "cloudworlds" {
    execute {
        load world "skyblock_1" with polar_storage_loader(mysql {
            host: "localhost"
            database: "mc"
            user: "root"
            password: "hunter2"
        })
        load world "skyblock_2" with polar_storage_loader(files "data/worlds")
    }
}
```

Passing anything that isn't a loader is caught at compile time:

```
e_loader.sw:3:33: error: expected a world loader (anvil_loader, polar_loader, or polar_storage_loader), got String
```

## World statements

| Form | Effect |
|---|---|
| `create world "name" [readonly] with <loader>` | new empty world; `readonly` skips saving |
| `load world "name" with <loader>` | load into the instance registry |
| `unload world "name" [without saving] [teleporting players to <location>]` | unload; optionally evacuate players first |
| `save world "name"` | flush to its loader |
| `clone world "a" to "b" with <loader>` | copy world bytes under a new name |
| `delete world "name" with <loader>` | remove from storage |
| `import anvil world "path" as "name" with <loader>` | one-way vanilla → Polar migration |

And the lookup expressions:

| Expression | Type |
|---|---|
| `world("name")` | `optional<World>` — the loaded instance |
| `world_exists("name", <loader>)` | `Boolean` — exists in storage (loaded or not) |
| `all_worlds(<loader>)` | `list<String>` — every world name in that loader |

```swoftlang
command "minigame" {
    execute {
        // fresh arena per round: clone the template, play, throw it away
        if world_exists("arena_template", polar_loader("worlds")) {
            clone world "arena_template" to "arena_live" with polar_loader("worlds")
            load world "arena_live" with polar_loader("worlds")
        }
    }
}

command "endgame" {
    execute {
        unload world "arena_live" without saving teleporting players to location(0.5, 82.0, 0.5)
        delete world "arena_live" with polar_loader("worlds")
        send "<green>Arena recycled." to sender
    }
}

command "worlds" {
    execute {
        loop all_worlds(polar_loader("worlds")) as w {
            send "<gray>- ${w}" to sender
        }
    }
}
```

`import anvil world` reads a vanilla save once and writes it through the target
loader — the standard migration path from a world you built in singleplayer:

```swoftlang
command "migrate" {
    execute {
        import anvil world "vanilla/world" as "hub" with polar_storage_loader(files "data/worlds")
    }
}
```

## World properties

| Property | Type | Access |
|---|---|---|
| `time` | `Integer` | read/write — world time in ticks |
| `time_rate` | `Integer` | read/write — ticks added per server tick (0 freezes time) |

```swoftlang
command "midnight" {
    execute {
        set sender.world.time to 18000
        set sender.world.time_rate to 0      // stay midnight
    }
}
```

## Blocks

Editing the blocks inside a loaded world — `set block at`, `fill blocks`, `place ... at`,
`remove block at`, and reading one back with `block_at` — lives in
[Blocks](./blocks#placing-and-reading-blocks), the single home for block values, states,
NBT, custom tags, `block_handler`, and `placement_rule`.

::: tip Polar dependency
Polar support rides `dev.hollowcube:polar`, pinned to a release compatible with the
pinned Minestom snapshot. Anvil needs no extra dependency.
:::
