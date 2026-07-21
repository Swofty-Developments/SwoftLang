---
title: NPCs
---

# NPCs

::: warning Retired addon — now a first-class construct
The `npcs` addon has been replaced by the built-in [`npc`](/1.1.0/reference/npcs) declaration:
`npc "name" { location, name, skin, look_at_players, on_click(player) { ... } }` with
`set npc` / `remove npc` statements — the spawn packets and the head-look trigonometry
now live in a dedicated Java runtime, and click handlers are inline typed bodies. The
old `import "npcs"` API and its `spawn_npc` / `on_npc_click` functions are gone.
:::

Everything the addon did — skins, click handlers, nearest-player head tracking — is now
one declaration the compiler checks. See the [first-class NPC reference](/1.1.0/reference/npcs)
for the construct and its statements.

The retired addon was ~400 lines of SwoftLang over the [raw packet](/1.1.0/reference/packets)
surface: player-info + spawn packets for the entity, a polynomial `atan2`/`sqrt` for the
head-look, and a closure-chain registry for state. Those techniques are still teachable
on their own — the [writing-an-addon tutorial](./writing-an-addon) and the
[raw packets reference](/1.1.0/reference/packets) cover the packet and registry patterns — but
the NPC itself is no longer something you assemble by hand.
