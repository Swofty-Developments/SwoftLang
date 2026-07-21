# Dispensers & Droppers

Dispenser and dropper blocks carry a real block-entity inventory. Fill one, trigger it,
and it pops an item in the direction it faces —
launching arrows, snowballs, eggs, and ender pearls as projectiles, and ejecting
everything else as a dropped item. Every fire passes through the cancellable
`BlockDispense` event, and a script can fire one directly with `dispense from`.

```swoftlang
command "dispense-demo" {
    execute {
        dispense from location(0.0, 64.0, 0.0)
        send "<gray>Fired the dispenser at 0, 64, 0." to sender
    }
}
```

## Block-entity inventories

A placed dispenser or dropper owns a 3×3 inventory. Right-clicking the block opens it,
and its contents live for as long as the block does — kept per block, keyed by world
position. Breaking the block drops its remaining contents into the world and clears the
store. There is nothing to declare: the inventory exists the moment the block is placed.

## How a dispenser fires

A dispenser or dropper activates three ways:

| Trigger | What activates it |
|---|---|
| A lever or button | toggling an adjacent lever/button *on* fires the block |
| A redstone block | placing a redstone block next to the dispenser fires it |
| `dispense from <location>` | a script fires the block at that position directly |

When it fires, the block pops **one** item, advancing through its slots round-robin just
like vanilla. Droppers always eject the item as a dropped entity. Dispensers inspect the
item first: **arrows, snowballs, eggs, and ender pearls launch as projectiles** along the
block's facing direction; everything else ejects as a dropped item with the usual spread.

## `dispense from`

`dispense from <location>` fires the dispenser or dropper at that block position from a
script — the third activation path, and the one you reach for in commands and events:

```swoftlang
dispense from location(10.0, 65.0, 10.0)
```

The expression must be a `Location`; if the block there is not a dispenser or dropper,
the statement is a no-op at that position (nothing to fire).

## The `BlockDispense` event

Every fire — lever, redstone, or `dispense from` — raises `BlockDispense` *before* the
item moves, so a handler can watch it, swap what comes out, or stop it entirely.

| Property | Type | Access | Meaning |
|---|---|---|---|
| `location` | `Location` | ro | the dispenser's position |
| `block` | `String` | ro | the block type (`dispenser` or `dropper`) |
| `item` | `optional<Item>` | rw | the item about to be dispensed — `none` when the block is empty |
| `direction` | `Vec` | ro | the facing direction the item will take |
| `cancelled` | `Boolean` | rw | set to stop the dispense |

```swoftlang
event BlockDispense {
    execute {
        send "<gray>A dispenser fired at ${event.location}." to all players
    }
}
```

Because `item` is read-write and `optional`, you can substitute the payload — handle the
empty case with the usual [optional](/1.1.0/guide/options) discipline:

```swoftlang
event BlockDispense {
    execute {
        if event.item exists {
            if event.item.material is "minecraft:arrow" {
                // turn every dispensed arrow into a snowball
                set event.item to item("SNOWBALL")
            }
        }
    }
}
```

Cancel to jam the block — nothing leaves it:

```swoftlang
event BlockDispense {
    execute {
        if event.block is "dropper" {
            cancel event
        }
    }
}
```

::: tip Projectiles from a dispenser
A dispenser firing an arrow or snowball produces a real projectile entity — the same
kind you get from [`launch projectile`](./entities#launching-projectiles), with its
flight and impact surfacing through the projectile-collide events. The
[throwable slime example](/1.1.0/examples/throwable-slime) dispenses slime balls as bouncing
projectiles this way.
:::
