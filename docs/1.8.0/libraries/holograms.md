---
title: Holograms
---

# Holograms

::: warning Retired addon — now a first-class construct
The `holograms` addon has been replaced by the built-in
[`hologram`](/1.8.0/reference/holograms) declaration:
`hologram "name" { location, billboard, lines { ... } }` with `show` / `set line` /
`move` statements, per-viewer text, and a typechecked line DSL — backed by a dedicated
Java runtime instead of a hand-rolled closure chain. The old `import "holograms"` API
and its `create_hologram` / `add_hologram_line` functions are gone.
:::

Everything the addon did is now one declaration the compiler checks. See the
[first-class hologram reference](/1.8.0/reference/holograms) for the construct, its statements,
and the per-viewer rules.

The retired addon kept its line handles in an association chain of closures and computed
the stacking offsets in SwoftLang by hand. That pattern — a name-keyed registry built
from closures — is still worth knowing, and the
[writing-an-addon tutorial](./writing-an-addon) teaches it from scratch; the hologram
stacking itself now lives in the runtime.
